#include "utils.h"

MiddlewareController::OperationMode mid::convert::qStringToOpMode(QString mode){
    QString normalized = mode.toLower().trimmed();

    if(normalized == "lan"){
        return  MiddlewareController::OperationMode::Lan;
    }else if(normalized == "network"){
        return MiddlewareController::OperationMode::Network;
    }else if(normalized == "http"){
        return MiddlewareController::OperationMode::RestApi;
    }

    return MiddlewareController::OperationMode::Unknow;
}

MiddlewareController::OperationMode mid::convert::stdStringToOpMode(std::string mode)
{
    return qStringToOpMode(QString::fromStdString(mode));
}
