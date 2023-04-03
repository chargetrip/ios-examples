//
//  SubscriptionService.swift
//  Examples
//
//  Created by Wouter van de Kamp on 27/03/2023.
//

import Foundation

struct InitOperation: Encodable {
    var id: String?
    var type: String
    var payload: [String: String]
}

struct Subscription: Encodable {
    var id: String
    var type: String
    var payload: Payload
}

struct Payload: Encodable {
    var key: String?
    var query: String
    var variables: [String: String]
}

enum OperationTypes: String {
    case connectionInit = "connection_init"
    case connectionAck = "connection_ack"
    case connectionError = "connection_error"
    case connectionKeepAlive = "ka"
    case connectionTerminated = "connection_terminate"
    case start = "start"
    case data = "data"
    case error = "error"
    case complete = "complete"
    case stop = "stop"
}

class WebsocketManager: NSObject, ObservableObject {
//    public weak var delegate: WebsocketDelegate?

    private var queue: [Subscription] = []
    private var webSocketTask: URLSessionWebSocketTask?
    private var connectingPayload: [String: String]
    private var urlRequest: URLRequest?
    private var isAck = false

    public required init(
        with urlRequest: URLRequest,
        connectingPayload: [String: String] = [:]
    ) {
        self.urlRequest = urlRequest
        self.connectingPayload = connectingPayload
    }

    func connect() {
        guard let urlRequest = urlRequest else { return }
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: urlRequest)
        webSocketTask?.resume()

        let initOperation = InitOperation(
            type: OperationTypes.connectionInit.rawValue,
            payload: connectingPayload
        )

        if let initMessage = try? JSONEncoder().encode(initOperation) {
            send(message: initMessage)
        }

        print("Connecting")
    }

    private func send(message: Data) {
        let message = URLSessionWebSocketTask.Message.data(message)
        sendMessage(message: message)
    }

    func send(message: Subscription) {
        if !isAck {
            queue.append(message)
            return
        }

        if let message = try? JSONEncoder().encode(message) {
            let urlSessionMessage = URLSessionWebSocketTask.Message.data(message)
            sendMessage(message: urlSessionMessage)
        }
    }

    private func sendMessage(message: URLSessionWebSocketTask.Message) {
        webSocketTask?.send(message) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                print("Could not send message because: \(error)")
                return
            }

            self.receive()
        }
    }

    private func receive() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                print(error)
            case .success(.data(let data)):
//                self.delegate?.didReceiveData(data: data)
                self.receive()
            case .success(.string(let string)):
                self.handleMessageTypes(message: string)
                self.receive()
            @unknown default:
                break
            }
        }
    }

    private func getMessageType(message: String) -> OperationTypes? {
        if let messageData = message.data(using: .utf8, allowLossyConversion: false) {
            do {
                let json = try JSONSerialization.jsonObject(with: messageData, options: []) as? [String: Any]
                guard let type = json?["type"] as? String else { return nil }
                let operationType = OperationTypes(rawValue: type)
                return operationType
            } catch let error {
                print("Websocket Manager: could not deserialize message from the server. Error code: \(error)")
            }
        }

        return nil
    }

    private func handleMessageTypes(message: String) {
        guard let operationType = getMessageType(message: message) else { return }

        switch operationType {
        case .connectionAck:
            isAck = true

            if !queue.isEmpty {
                queue.forEach { send(message: $0) }
            }

            queue.removeAll()
        case .data:
            print(message)
        case .connectionKeepAlive:
            webSocketTask?.sendPing(pongReceiveHandler: { error in
                if error != nil {
                    print("Keep Alive Error: \(String(describing: error))")
                }
            })
        case .connectionError:
            isAck = false
            print("Received a connection error. Message details: \(message)")
        case .error:
            isAck = false
            print("Received an error. Message details: \(message)")
        case .complete:
            isAck = false
            print("Operations completed. Closing connection.")
        default:
            print("Unexpected message from server")
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isAck = false
        webSocketTask = nil
    }
}
