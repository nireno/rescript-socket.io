module Make = (Messages: Messages.S) => {
  type t
  @new external create: unit => t = "io"
  @new external createWithUrl: string => t = "io"
  @send external _emit: (t, string, 'a) => unit = "emit"
  let emit = (socket, obj: Messages.clientToServer) =>
    _emit(socket, "message", Json.toValidJson(obj))
  @send external _emitWithAck: (t, string, 'a, 'b => unit) => unit = "emit"
  let emitWithAck = (socket, obj: Messages.clientToServer, ack: Messages.serverToClient => unit) =>
    _emitWithAck(socket, "message", Json.toValidJson(obj), message =>
      ack(Json.fromValidJson(message))
    )
  @send external _on: (t, string, 'a => unit) => unit = "on"
  let on = (socket, func: Messages.serverToClient => unit) =>
    _on(socket, "message", obj => func(Json.fromValidJson(obj)))
}
