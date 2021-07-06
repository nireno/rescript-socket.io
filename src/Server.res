type serverT

type socketT

type room = string

module Make = (Messages: Messages.S) => {
  @module external create: unit => serverT = "socket.io"
  @module external createWithHttp: 'a => serverT = "socket.io"

  /* **
   * makeOptions is a simple way to get around the fact that ocaml won't allow you to declare
   * partially defined records (and row polymorphism + ad hoc polymorphism is tricky in ocaml)
   * This allows you to create a JS object with any of the defined properties, allowing to omit
   * any number of them.
   */
  type createOptionsT
  @obj
  external makeOptions: (
    ~pingTimeout: int=?,
    ~pingInterval: int=?,
    ~maxHttpBufferSize: int=?,
    ~transports: list<string>=?,
    ~allowUpgrades: bool=?,
    ~perMessageDeflate: int=?,
    ~httpCompression: int=?,
    ~cookie: string=?,
    ~cookiePath: string=?,
    ~wsEngine: string=?,
    unit,
  ) => createOptionsT = ""
  @module
  external createWithOptions: createOptionsT => serverT = "socket.io"
  @module
  external createWithHttpAndOption: ('a, createOptionsT) => serverT = "socket.io"
  @module
  external createWithPort: (int, createOptionsT) => serverT = "socket.io"

  /* ** */
  @send external serveClient: (serverT, bool) => serverT = "serveClient"

  /* ** */
  @send external path: (serverT, string) => serverT = "path"

  /* **
   * This kind of function is annoying because it relies on the type of another module which you might not
   * care about (here https://github.com/socketio/socket.io-adapter), and which is defined by someone else.
   * The only idea I have to typecheck this is to make sure this type is a module type representing an
   * interface, and have the external package also use that module signature. The problem is to keep them in
   * sync. No clue how to do that.
   */
  @send external adapter: (serverT, 'a) => serverT = "adapter"

  /* ** */
  @send external origins: (serverT, string) => serverT = "origins"
  @send
  external originsWithFunc: (serverT, ('a, bool) => unit) => serverT = "origins"

  /* ** */
  @send external close: serverT => unit = "close"

  /* ** This is the same as "server.listen". */
  @send
  external attach: (serverT, 'a, createOptionsT) => serverT = "attach"
  @send
  external attachWithPort: (serverT, int, createOptionsT) => serverT = "attach"

  /* ** */
  @send external _emit: ('a, string, 'b) => unit = "emit"

  /* **
   * socketT is the representation of a connection received by the server.
   * It's a pipeline through which one can emit and listen to events.
   */
  module Socket = {
    @get external getId: socketT => room = "id"
    @get external getHandshake: socketT => 'a = "handshake"
    /* Here 'a means that you can send anything you want, and it'll depend on
     Bucklescript */
    @send
    external _on: (socketT, string, Messages.clientToServer => unit) => unit = "on"
    let on = (socket, func) => _on(socket, "message", obj => func(Json.fromValidJson(obj)))

    @send
    external _onWithAck: (
      socketT,
      string,
      (Messages.clientToServer, Messages.serverToClient => unit) => unit,
    ) => unit = "on"
    let onWithAck = (socket, func) =>
      _onWithAck(socket, "message", (obj, ack) => {
        let ack = obj => Js.Json.stringify(obj) |> ack
        func(Json.fromValidJson(obj), ack)
      })

    /* ** */
    let emit = (socket: socketT, obj: Messages.serverToClient) =>
      _emit(socket, "message", Js.Json.stringify(obj))

    /* ** */
    type broadcastT
    @get
    external _unsafeGetBroadcast: socketT => broadcastT = "broadcast"
    let broadcast = (socket, data: Messages.serverToClient) =>
      _emit(_unsafeGetBroadcast(socket), "message", Js.Json.stringify(data))

    /* ** */
    @send external join: (socketT, string) => socketT = "join"
    @send external leave: (socketT, string) => socketT = "leave"
    @send external to_: (socketT, string) => socketT = "to"
    @send external compress: (socketT, bool) => socketT = "compress"
    @send external disconnect: (socketT, bool) => socketT = "disconnect"
    @send
    external use: (socketT, ('a, ~next: unit => unit) => unit) => unit = "use"

    /* ** */
    @send
    external _once: (socketT, string, Messages.serverToClient => unit) => unit = "once"
    let once = (socket, func) => _once(socket, "message", obj => func(Json.fromValidJson(obj)))

    /* ** Volatile */
    type volatileT
    @get external getVolatile: socketT => volatileT = "volatile"
    @send
    external _volatileEmit: (volatileT, string, 'a) => unit = "emit"
    let volatileEmit = (server: socketT, obj: Messages.serverToClient): unit =>
      _volatileEmit(getVolatile(server), "message", Js.Json.stringify(obj))
    let onDisconnect = (socket, cb) => _on(socket, "disconnect", _ => cb())
  }
  @send
  external _unsafeOnConnect: (serverT, string, socketT => unit) => unit = "on"
  let onConnect = (io, cb) => _unsafeOnConnect(io, "connection", cb)
}
