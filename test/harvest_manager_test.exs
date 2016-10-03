defmodule HarvestManagerTest do
  use ExUnit.Case, async: true
  alias Experimental.GenStage
  use GenStage

  setup do
    {:ok, manager} = Enricher.HarvestManager.start_link
    {:ok, manager: manager}
  end
  describe "status" do
    test "it returns a status struct", %{manager: manager} do
      status = Enricher.HarvestManager.status(manager)
      assert is_map(status)
      assert status.docs_processed == 0
      assert status.in_progress == false
    end
  end
  @tag :integration
  describe "start_harvest" do
    test "it updates the status", %{manager: manager} do
      status = Enricher.HarvestManager.status(manager)
      Enricher.HarvestManager.start_harvest(manager, "full", "http://solr.test")
      updated_status = Enricher.HarvestManager.status(manager) 
      assert updated_status.start_time > status.start_time
      assert updated_status.in_progress == true
    end
  end
  describe "update_count" do
    test "it updates the count", %{manager: manager} do
      Enricher.HarvestManager.update_count(manager, 20)
      Enricher.HarvestManager.update_count(manager, 20)
      assert Enricher.HarvestManager.status(manager) |> Map.get(:docs_processed) == 40
    end
  end
  describe "update_status" do
    test "updates the manager status", %{manager: manager} do
      Enricher.HarvestManager.update_status(manager, %{in_progress: true, docs_processed: 1_000})
      assert Enricher.HarvestManager.status(manager) |> Map.get(:docs_processed) == 1_000
      assert Enricher.HarvestManager.status(manager) |> Map.get(:in_progress) == true 
    end
  end
  describe "update_batch_size" do
    test "updates the batch size", %{manager: manager} do
      Enricher.HarvestManager.update_batch_size(manager, "5000") 
      assert Enricher.HarvestManager.status(manager) |> Map.get(:batch_size) == "5000" 
    end
  end
  describe "supervision" do
    test "it can be started with a name by a supervisor" do
      import Supervisor.Spec
      children = [
        worker(Enricher.HarvestManager, [TestManager])
      ]
      {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)
      status = Enricher.HarvestManager.status(TestManager)
      assert status.in_progress == false
    end
  end
  describe "register_updater/2" do
    test "it allows us to register an updater", %{manager: manager} do
      {:ok, pid} = GenStage.start_link(UpdateStage, [])
      Enricher.HarvestManager.register_updater(manager, pid)
      assert Enricher.HarvestManager.updaters(manager) == [pid]
    end
  end
  describe "deregister_updater/2" do
    test "it disconnects an updater", %{manager: manager} do
      {:ok, pid} = GenStage.start_link(UpdateStage, [])
      Enricher.HarvestManager.register_updater(manager, pid)
      Enricher.HarvestManager.deregister_updater(manager, pid)
      assert Enricher.HarvestManager.updaters(manager) == []
    end
  end
end
