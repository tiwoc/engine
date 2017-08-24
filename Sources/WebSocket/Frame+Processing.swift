extension WebSocket {
    func processFrame(_ frame: Frame) {
        frame.unmask()
        
        func processString() {
            // invalid string
            guard let string = frame.payload.string() else {
                self.connection.client.close()
                return
            }
            
            self.textStream.outputStream?(string)
        }
        
        func processBinary() {
            self.binaryStream.outputStream?(frame.payload)
        }
        
        switch frame.opCode {
        case .text:
            processString()
        case .binary:
            processBinary()
        case .ping:
            do {
                // reply the input
                let pongFrame = try Frame(op: .pong , payload: frame.payload, mask: nil, isMasked: frame.isMasked)
                self.connection.inputStream(pongFrame)
            } catch {
                self.connection.errorStream?(error)
            }
        case .continuation:
            processBinary()
        case .close:
            self.connection.client.close()
        case .pong:
            return
        }
    }
}