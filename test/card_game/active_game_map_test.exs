defmodule CardGame.ActiveGameMapTest do
  use ExUnit.Case
  doctest CardGame.ActiveGameMap

  alias CardGame.ActiveGameMap

  setup_all do
    {:ok, pid} = ActiveGameMap.start_link()
    %{agent_pid: pid}
  end

  describe "put/3 - " do
    test "adds a new key on the agent", %{agent_pid: agent_pid} do
      assert :ok = ActiveGameMap.put(agent_pid, "test", "test")
    end
  end

  describe "get/2 - " do
    test "retrives the key from agent", %{agent_pid: agent_pid} do
      assert :ok = ActiveGameMap.put(agent_pid, "test", "test")
      assert "test" = ActiveGameMap.get(agent_pid, "test")
    end

    test "returns nil value if key is not present", %{agent_pid: agent_pid} do
      assert nil == ActiveGameMap.get(agent_pid, "test1")
    end
  end
end
