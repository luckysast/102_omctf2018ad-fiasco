defmodule Fiasco.BSPSD do
  use GenServer
  require Logger

  def start_link(_arg) do
    Logger.info("Starting BSPSD Connector")

    ip = Application.get_env(:fiasco, :bsps_ip, "localhost")
    port = Application.get_env(:fiasco, :bsps_port, 8800)

    GenServer.start_link(__MODULE__, [ip, port], name: BSPSD)
    # GenServer.call(BSPSD, :action) #=> :result
  end

  def init([ip, port]) do
    # Logger.debug inspect([ip,port])
    socket = connect(ip, port)

    {:ok, socket}
  end

  def connect(ip, port) do
    case Socket.Web.connect(ip, port, path: "/ws") do
      {:error, error} ->
        Logger.error(inspect(error))
        nil

      {:ok, socket} ->
        socket

      _ ->
        Logger.error("UNDEFINDED ERROR")
        nil
    end
  end

  def handle_call({:createAccount, name}, _from, socket) do
    Logger.debug("BSPSD: create service user: " <> name)

    {socket, data} =
      cond do
        socket == nil ->
          ip = Application.get_env(:fiasco, :bsps_ip, "localhost")
          port = Application.get_env(:fiasco, :bsps_port, 8800)
          socket = connect(ip, port)
          data = {:error, %{"error" => "Reconnecting BSPSD, try again later"}}
          {socket, data}

        true ->
          payload =
            Poison.encode!(%{
              "version" => 1,
              "opcode" => 0x02,
              "PoW_hashid" => 0,
              "PoW_result" => "",
              "timestamp" => :os.system_time(:seconds),
              "nonce" => 0,
              "data" => %{"Name" => name}
            })

          socket
          |> Socket.Web.send!({:text, payload})

          {:text, resp} = socket |> Socket.Web.recv!()
          resp = Poison.decode!(resp)

          # get id
          # "id":"5e87329db0604bc6648b6f946fa93a08"
          uid =
            case resp do
              %{"opcode" => 2} -> resp["data"]["id"]
              %{"opcode" => 0} ->
                Logger.error "Can't create service user: "
                Logger.error inspect(resp["data"]["Message"])
                Process.exit(self(), :createUserError)
            end

          payload =
            Poison.encode!(%{
              "version" => 1,
              "opcode" => 0x11,
              "PoW_hashid" => 0,
              "PoW_result" => "",
              "timestamp" => :os.system_time(:seconds),
              "nonce" => 0,
              "data" => %{"client" => uid}
            })

          socket
          |> Socket.Web.send!({:text, payload})

          {:text, resp} = socket |> Socket.Web.recv!()
          resp = Poison.decode!(resp)

          # get id
          # "id":"5e87329db0604bc6648b6f946fa93a08"
          data =
            case resp do
              %{"opcode" => 17} -> {:ok, resp["data"]["id"]}
              %{"opcode" => 0} ->
                Logger.error "Can't create service account: "
                Logger.error inspect(resp["data"]["Message"])
                Process.exit(self(), :createAccError)
            end

          {socket, data}
      end

    {:reply, data, socket}
  end

  def handle_call({:userByToken, token}, _from, socket) do
    Logger.debug("BSPSD: get user by token: " <> token)

    {socket, data} =
      cond do
        socket == nil ->
          ip = Application.get_env(:fiasco, :bsps_ip, "localhost")
          port = Application.get_env(:fiasco, :bsps_port, 8800)
          socket = connect(ip, port)
          data = {:error, %{"error" => "Reconnecting BSPSD, try again later"}}
          {socket, data}

        true ->
          payload =
            Poison.encode!(%{
              "version" => 1,
              "opcode" => 0x0A,
              "PoW_hashid" => 0,
              "PoW_result" => "",
              "timestamp" => :os.system_time(:seconds),
              "nonce" => 0,
              "data" => %{"token" => token}
            })

          socket
          |> Socket.Web.send!({:text, payload})

          {:text, resp} = socket |> Socket.Web.recv!()
          resp = Poison.decode!(resp)

          data =
            case resp do
              %{"opcode" => 10} -> {:ok, resp["data"]["clientid"]}
              %{"opcode" => 0} -> {:error, %{"error" => resp["data"]["Message"]}}
            end

          # %{"data" => %{"Error" => 0, "Message" => "Session isn't exists"}, "opcode" => 0, "version" => 1}
          # %{"data" => %{"LastUsed" => "0001-01-01T00:00:00Z",
          #                 "clientid" => "8a863b145dc6e4ed7ac41c08f7536c47",
          #                 "data" => "",
          #                 "id" => "8ba3fb16253f6877b8899a9be7e3171506f0824f2c2d64d28b213c2b"},
          #     "opcode" => 10,
          #     "version" => 1}
          {socket, data}
      end

    {:reply, data, socket}
  end

  def handle_call({:userAccounts, userID}, _from, socket) do
    Logger.debug("BSPSD: get accounts by user ID: " <> userID)

    {socket, data} =
      cond do
        socket == nil ->
          ip = Application.get_env(:fiasco, :bsps_ip, "localhost")
          port = Application.get_env(:fiasco, :bsps_port, 8800)
          socket = connect(ip, port)
          data = {:error, %{"error" => "Reconnecting BSPSD, try again later"}}
          {socket, data}

        true ->
          payload =
            Poison.encode!(%{
              "version" => 1,
              "opcode" => 0x06,
              "PoW_hashid" => 0,
              "PoW_result" => "",
              "timestamp" => :os.system_time(:seconds),
              "nonce" => 0,
              "data" => %{"id" => userID}
            })

          socket
          |> Socket.Web.send!({:text, payload})

          {:text, resp} = socket |> Socket.Web.recv!()
          resp = Poison.decode!(resp)
          # Logger.debug inspect(resp)

          data =
            case resp do
              %{"opcode" => 6} -> {:ok, resp["data"]}
              %{"opcode" => 0} -> {:error, %{"error" => resp["data"]["Message"]}}
            end

          # %{"data" => %{"Error" => 0, "Message" => "Client is not exists"}, "opcode" => 0, "version" => 1}
          # %{"data" => nil, "opcode" => 6, "version" => 1}
          {socket, data}
      end

    {:reply, data, socket}
  end

  def handle_call({:transferMoney, senderID, recipientID, amount}, _from, socket) do
    Logger.debug("BSPSD: get transfer query from user ID")

    # GET FROM ENVIRONMENT??
    # serviceAccountID = 2_248_135_574

    {socket, data} =
      cond do
        socket == nil ->
          ip = Application.get_env(:fiasco, :bsps_ip, "localhost")
          port = Application.get_env(:fiasco, :bsps_port, 8800)
          socket = connect(ip, port)
          data = {:error, %{"error" => "Reconnecting BSPSD, try again later"}}
          {socket, data}

        true ->
          payload =
            Poison.encode!(%{
              "version" => 1,
              "opcode" => 0x13,
              "PoW_hashid" => 0,
              "PoW_result" => "",
              "timestamp" => :os.system_time(:seconds),
              "nonce" => 0,
              "data" => %{
                "sender" => senderID,
                "recipient" => recipientID,
                "amount" => amount
              }
            })

          socket
          |> Socket.Web.send!({:text, payload})

          {:text, resp} = socket |> Socket.Web.recv!()
          resp = Poison.decode!(resp)
          # Logger.debug inspect(resp)

          data =
            case resp do
              %{"opcode" => 19} -> {:ok, resp["data"]}
              %{"opcode" => 0} -> {:error, %{"error" => resp["data"]["Message"]}}
            end

          # %{"data" => %{"Error" => 0, "Message" => "Client is not exists"}, "opcode" => 0, "version" => 1}
          # {"version":1,"opcode":19,"data":{"status":true}}
          {socket, data}
      end

    {:reply, data, socket}
  end

  # def handle_call({:payToWinner, accountID, amount}, _from, socket) do
  #   Logger.debug("BSPSD: get PAY query from user ID:")
  #
  #   # GET FROM ENVIRONMENT??
  #   serviceAccountID = 901081080
  #
  #   {socket, data} =
  #     cond do
  #       socket == nil ->
  #         ip = Application.get_env(:fiasco, :bsps_ip, "localhost")
  #         port = Application.get_env(:fiasco, :bsps_port, 8800)
  #         socket = connect(ip, port)
  #         data = {:error, %{"error" => "Reconnecting BSPSD, try again later"}}
  #
  #         {socket, data}
  #
  #       true ->
  #         payload =
  #           Poison.encode!(%{
  #             "version" => 1,
  #             "opcode" => 0x13,
  #             "PoW_hashid" => 0,
  #             "PoW_result" => "",
  #             "timestamp" => :os.system_time(:seconds),
  #             "nonce" => 0,
  #             "data" => %{
  #               "sender" => serviceAccountID,
  #               "recipient" => accountID,
  #               "amount" => amount
  #             }
  #           })
  #
  #         socket
  #         |> Socket.Web.send!({:text, payload})
  #
  #         {:text, resp} = socket |> Socket.Web.recv!()
  #         resp = Poison.decode!(resp)
  #         # Logger.debug inspect(resp)
  #
  #         data =
  #           case resp do
  #             %{"opcode" => 19} -> {:ok, resp["data"]}
  #             %{"opcode" => 0} -> {:error, %{"error" => resp["data"]["Message"]}}
  #           end
  #
  #         # %{"data" => %{"Error" => 0, "Message" => "Client is not exists"}, "opcode" => 0, "version" => 1}
  #         # {"version":1,"opcode":19,"data":{"status":true}}
  #         {socket, data}
  #     end
  #
  #   {:reply, data, socket}
  # end

  def handle_info(:work, state) do
    # Do the work you desire here
    {:noreply, state}
  end

  def handle_info(:restart, state) do
    # Do the work you desire here

    ip = Application.get_env(:fiasco, :bsps_ip, "localhost")
    port = Application.get_env(:fiasco, :bsps_port, 8800)

    socket = connect(ip, port)

    {:noreply, socket}
  end
end
