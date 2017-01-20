//
//  Soap.swift
//  School Notices
//
//  Created by Murray Collingwood on 17/1/17.
//  Copyright © 2017 Focus Computing Pty Ltd. All rights reserved.
//

import Foundation

protocol SoapResponse {
    func soapFailed(code: Int!, errorObject: Any!) -> Void
    func soapSuccess(xml: XMLNode!) -> Void
}

class Soap {
    
    
    public static func call(url: String!, withXMLRequests requests: [XMLNode]!, from: SoapResponse!) {

        guard let currentUrl = URL(string: url) else {
            print("URL failed")
            from.soapFailed(code: 900, errorObject: "url is not valid: " + url)
            return
        }
        
        var urlRequest = URLRequest(url: currentUrl)

        guard let soapRequest: String = self.createXML(requests) else {
            print("SOAP failed")
            from.soapFailed(code: 901, errorObject: "Unable to create SoapRequest from supplied nodes: " + requests.debugDescription)
            return
        }
        
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = soapRequest.data(using: .utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil else {
                // print(error.debugDescription)
                from.soapFailed(code: 902, errorObject: error)
                return
            }
        
            guard let responseData = data else {
                // print("request didn't return any data")
                from.soapFailed(code: 903, errorObject: "Request did not return any data")
                return
            }

            // *** TODO ***  Not sure how we are supposed to know if this worked
            let soapResponse = XML(data: responseData)
            // else {
            // print("unable to load XML document")
            // from.soapFailed(code: 904, errorObject: "Unable to load data as XML: " + data.debugDescription)
            // return
            // }
            
            // print ("data = " + soapResponse[0].description) // Ignore the <?xml...?> wrapper
    
            // Read through the soapenv:Envelope | soapenv:Body | sobsQuery
            if let envelope = soapResponse[0] as XMLNode? {
                // print("envelope = " + envelope.name!)
                if envelope.name == "SOAP-ENV:Envelope" {
                    let body = envelope[0]
                    // print("body = " + body.name!)
                    if body.name == "SOAP-ENV:Body" {
                        let ns1 = body[0]
                        // print("ns1 = " + ns1.name!)
                        if ns1.name == "ns1:sobsQueryResponse" {
                            let sobsQuery = ns1[0]
                            // print("sobsQuery = " + sobsQuery.name!)
                            if sobsQuery.name == "sobsQuery" {
                                let sobsSoap = sobsQuery[0]
                                // print("sobs-soap = " + sobsSoap.name!)
                                if sobsSoap.name == "sobs-soap" {
                                    from.soapSuccess(xml: sobsSoap)
                                    return
                                }
                            }
                        }
                    }
                }
            }
            
            // General failure reading the response
            from.soapFailed(code: 905, errorObject: soapResponse)
            return
    
        }
        // Here we actually submit the thing above
        task.resume()
    
    }

    private static func createXML(_ additionalFunctions: [XMLNode]?) -> String? {
    
        guard let url = Bundle.main.url(forResource: "soap-template", withExtension: "xml") else {
            print("Unable to locate supporting file: soap-template.xml")
            return nil
        }
        
        guard let soapRequest = XML(contentsOf: url) else {
            print("Unable to load XML from soap-template.xml")
            return nil
        }

        let soap = XMLNode(name: "sobs-soap")
        soap.attributes["version"] = "2.3"

        if let nodes = additionalFunctions {
            for node in nodes {
                soap.addChild(node)
            }
        }

        let query = XMLNode(name: "sobs:sobsQuery")
        query.addChild(soap)
        let body = soapRequest[0]["soapenv:Body"]
        body?.addChild(query)

        return soapRequest.description
    }


    

}
