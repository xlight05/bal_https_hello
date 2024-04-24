import ballerina/http;
import ballerina/io;
import ballerina/xmldata;

listener http:Listener securedEP = new (9090,
    secureSocket = {
        key: {
            path: "./security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
);

final http:Client nettyEP = check new("https://netty:8688",
    secureSocket = {
        cert: {
            path: "./security/ballerinaTruststore.p12",
            password: "ballerina"
        },
        verifyHostName: false
    }
);

service /transform on securedEP {

    function init() {
        io:println("Service started on port 9090");
    }

    resource function post .(http:Request req) returns http:Response|error? {
        json|error payload = req.getJsonPayload();
        if payload is json {
            xml|xmldata:Error? xmlPayload = xmldata:fromJson(payload);
            if xmlPayload is xml {
                http:Request clinetreq = new;
                clinetreq.setXmlPayload(xmlPayload);
                http:Response|http:ClientError response = nettyEP->post("/service/EchoService", clinetreq);
                if response is http:Response {
                    return response;
                } else {
                    http:Response res = new;
                    res.statusCode = 500;
                    res.setPayload(response.message());
                    return res;
                }
            } else if xmlPayload is xmldata:Error {
                http:Response res = new;
                res.statusCode = 400;
                res.setPayload(xmlPayload.message());
                return res;
            }
        } else {
            http:Response res = new;
            res.statusCode = 400;
            res.setPayload(payload.message());
            return res;
        }
    }
}
