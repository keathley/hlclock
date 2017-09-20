defmodule HLClock do
  @moduledoc """
  Hybrid Logical Clock

  Provides globally-unique, monotonic timestamps. Timestamps are bounded by the
  clock synchronization constraint, max_drift.

  Implementation assumes that timestamps are (at a minimum) regularly sent; a
  clock at rest will eventually be unable to generate timestamps due to assumed
  bounds on the logical clock relative to physical time.

  In order to account for physical time drift within the system, timestamps
  should regularly be exchanged between nodes. Generate a timestamp at one node
  via HLClock.send_timestamp/1; at the other node, call HLClock.recv_timestamp/2
  with the received timestamp from the first node.

  Inspired by https://www.cse.buffalo.edu/tech-reports/2014-04.pdf
  """

  alias HLClock.{NodeId, Timestamp}

  @doc """
  Starts and links the supervision tree.
  """
  def start_link(opts \\ []) do
    opts
    |> build_opts
    |> HLClock.Supervisor.start_link
  end


  @doc """
  Generate a single HLC Timestamp for sending to other nodes or
  local causality tracking
  """
  def send_timestamp do
    GenServer.call(HLClock.Server, :send_timestamp)
  end

  @doc """
  Given the current timestamp for this node and a provided remote timestamp,
  perform the merge of both logical time and logical counters. Returns the new
  current timestamp for the local node
  """
  def recv_timestamp(remote) do
    GenServer.call(HLClock.Server, {:recv_timestamp, remote})
  end

  @doc """
  Configurable clock synchronization parameter, ε. Defaults to 300 seconds
  """
  def max_drift(), do: Application.get_env(:hlclock, :max_drift_millis, 300_000)

  @doc """
  Determines if the clock's timestamp "happened before" a different timestamp
  """
  def before?(t1, t2) do
    Timestamp.before?(t1, t2)
  end

  defp build_opts(opts) do
    opts
    |> Keyword.put_new(:node_id, NodeId.hash())
  end
end
