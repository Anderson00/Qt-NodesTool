#include <QDebug>
#include <QCoreApplication>
#include <iostream>
#include <cxxopts.hpp>
#include "utils.h"

int main(int argc, char **argv){

    qInstallMessageHandler(mid::log::messageLogOutput);

    cxxopts::Options options("Middleware", "");
    options.add_options()
//            ("b,bar", "Param bar", cxxopts::value<std::string>())
//            ("d,debug", "Enable debugging", cxxopts::value<bool>()->default_value("false"))
//            ("f,foo", "Param foo", cxxopts::value<int>()->default_value("10"))
            ("m,mode", "Mode of middleware: lan, network, http", cxxopts::value<std::string>()->default_value("lan"))
            ("h,help", "Print usage");

    auto result = options.parse(argc, argv);

    if(result.count("help")){
        qDebug() << QString::fromStdString(options.help());
        qDebug() << "QString::fromStdString(options.help())";
        std::cout << options.help() << std::endl;
    }

    QCoreApplication app(argc, argv);


    return app.exec();
}
