#include <QDebug>
#include <QCoreApplication>
#include <iostream>
#include <cxxopts.hpp>

#include <src/controller/middlewarecontroller.h>
#include "utils.h"

int main(int argc, char **argv){

    qInstallMessageHandler(mid::log::messageLogOutput);

    cxxopts::Options options("Middleware", "");
    options.add_options()
            ("m,mode", "Mode of middleware: lan, network, http", cxxopts::value<std::string>()->default_value("lan"))
            ("d,dir", "Directory to input files to analyze: *.exe", cxxopts::value<std::string>()->default_value(""))
            ("h,help", "Print usage");

    auto result = options.parse(argc, argv);

    if(result.count("help")){
        qDebug() << QString::fromStdString(options.help());
    }

    QCoreApplication app(argc, argv);

    MiddlewareController midController(mid::convert::stdStringToOpMode(result["mode"].as<std::string>()),
            QString::fromStdString(result["dir"].as<std::string>()),
            &app);

    QObject::connect(&midController, &MiddlewareController::quit, &app, &QCoreApplication::quit);

    return app.exec();
}
