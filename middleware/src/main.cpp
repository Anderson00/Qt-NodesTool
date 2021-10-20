#include <QDebug>
#include <QCoreApplication>
#include <cxxopts.hpp>
#include "utils.h"

int main(int argc, char **argv){

    qInstallMessageHandler(mid::log::messageLogOutput);

    qDebug() << "testando";

    cxxopts::Options options("Middleware", "");
    options.add_options()
            ("b,bar", "Param bar", cxxopts::value<std::string>())
            ("d,debug", "Enable debugging", cxxopts::value<bool>()->default_value("false"))
            ("f,foo", "Param foo", cxxopts::value<int>()->default_value("10"))
            ("h,help", "Print usage");

    auto result = options.parse(argc, argv);

    if(result.count("help")){
        qDebug() << QString::fromStdString(options.help());
        printf("%s", options.help().c_str());
    }

    QCoreApplication app(argc, argv);


    return app.exec();
}
