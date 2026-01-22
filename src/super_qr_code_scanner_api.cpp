#include "super_qr_code_scanner_api.h"
#include <opencv2/opencv.hpp>
#include <opencv2/core/utils/logger.hpp>
#include <ReadBarcode.h>
#include <vector>
#include <set>
#include <cstring>
#include <future>
#include <thread>

static int opencvErrorHandler(int status, const char* func_name, const char* err_msg, const char* file_name, int line, void* userdata) {
    // Suppress OpenCV errors to avoid log spam on Android
    return 0;
}

static struct OpenCVInitializer {
    OpenCVInitializer() {
        // Disable plugin loading and suppress all OpenCV logging
        cv::utils::logging::setLogLevel(cv::utils::logging::LOG_LEVEL_SILENT);
        cv::redirectError(opencvErrorHandler);
    }
} opencv_initializer;

// Internal function to scan QR codes from cv::Mat
static std::vector<ZXing::Barcode> scanQRCodesInternal(const cv::Mat& image) {
    cv::Mat grayImage;
    if (image.channels() == 3 || image.channels() == 4) {
        cv::cvtColor(image, grayImage, cv::COLOR_BGR2GRAY);
    } else {
        grayImage = image;
    }
    
    std::vector<ZXing::Barcode> allResults;
    std::set<std::string> foundCodes;
    
    // Strategy 1: Original image
    {
        ZXing::ImageView imageView(grayImage.data, grayImage.cols, grayImage.rows, 
                                   ZXing::ImageFormat::Lum);
        
        ZXing::ReaderOptions options;
        options.setFormats(ZXing::BarcodeFormat::Any);
        options.setTryHarder(true);
        options.setTryRotate(true);
        options.setTryDownscale(true);
        options.setTryInvert(true);
        options.setMaxNumberOfSymbols(20);
        
        auto results = ZXing::ReadBarcodes(imageView, options);
        for (const auto& result : results) {
            if (foundCodes.find(result.text()) == foundCodes.end()) {
                foundCodes.insert(result.text());
                allResults.push_back(result);
            }
        }
    }
    
    // Strategy 2: Multiple scales
    for (double scale : {0.5, 1.5, 2.0, 2.5, 3.0}) {
        cv::Mat scaled;
        cv::resize(grayImage, scaled, cv::Size(), scale, scale, cv::INTER_CUBIC);
        
        ZXing::ImageView imageView(scaled.data, scaled.cols, scaled.rows, 
                                   ZXing::ImageFormat::Lum);
        
        ZXing::ReaderOptions options;
        options.setFormats(ZXing::BarcodeFormat::Any);
        options.setTryHarder(true);
        options.setTryRotate(true);
        options.setTryInvert(true);
        options.setMaxNumberOfSymbols(20);
        
        auto results = ZXing::ReadBarcodes(imageView, options);
        for (const auto& result : results) {
            if (foundCodes.find(result.text()) == foundCodes.end()) {
                foundCodes.insert(result.text());
                allResults.push_back(result);
            }
        }
    }
    
    return allResults;
}

QRScanResult* qr_scan_image(const char* image_path) {
    // Run image loading and scanning in a worker thread
    auto future = std::async(std::launch::async, [image_path]() -> QRScanResult* {
        cv::Mat image = cv::imread(image_path);
        if (image.empty()) {
            return nullptr;
        }
        
        auto results = scanQRCodesInternal(image);
        
        QRScanResult* scanResult = new QRScanResult();
        scanResult->count = results.size();
        
        if (scanResult->count > 0) {
            scanResult->results = new QRCodeResult[scanResult->count];
            
            for (int i = 0; i < scanResult->count; i++) {
                const auto& result = results[i];
                
                // Copy content
                const std::string& text = result.text();
                scanResult->results[i].content = new char[text.length() + 1];
                strcpy(scanResult->results[i].content, text.c_str());
                
                // Copy format
                std::string format = ToString(result.format());
                scanResult->results[i].format = new char[format.length() + 1];
                strcpy(scanResult->results[i].format, format.c_str());
            }
        } else {
            scanResult->results = nullptr;
        }
        
        return scanResult;
    });
    
    // Wait for the async task to complete and return the result
    return future.get();
}

QRScanResult* qr_scan_bytes(const unsigned char* image_data, int width, int height, int channels) {
    // Run image processing and scanning in a worker thread
    auto future = std::async(std::launch::async, [image_data, width, height, channels]() -> QRScanResult* {
        cv::Mat image;
        
        if (channels == 1) {
            image = cv::Mat(height, width, CV_8UC1, (void*)image_data).clone();
        } else if (channels == 3) {
            image = cv::Mat(height, width, CV_8UC3, (void*)image_data).clone();
        } else if (channels == 4) {
            image = cv::Mat(height, width, CV_8UC4, (void*)image_data).clone();
        } else {
            return nullptr;
        }
        
        auto results = scanQRCodesInternal(image);
        
        QRScanResult* scanResult = new QRScanResult();
        scanResult->count = results.size();
        
        if (scanResult->count > 0) {
            scanResult->results = new QRCodeResult[scanResult->count];
            
            for (int i = 0; i < scanResult->count; i++) {
                const auto& result = results[i];
                
                const std::string& text = result.text();
                scanResult->results[i].content = new char[text.length() + 1];
                strcpy(scanResult->results[i].content, text.c_str());
                
                std::string format = ToString(result.format());
                scanResult->results[i].format = new char[format.length() + 1];
                strcpy(scanResult->results[i].format, format.c_str());
            }
        } else {
            scanResult->results = nullptr;
        }
        
        return scanResult;
    });
    
    // Wait for the async task to complete and return the result
    return future.get();
}

void qr_free_result(QRScanResult* result) {
    if (result) {
        if (result->results) {
            for (int i = 0; i < result->count; i++) {
                delete[] result->results[i].content;
                delete[] result->results[i].format;
            }
            delete[] result->results;
        }
        delete result;
    }
}
