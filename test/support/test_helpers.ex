defmodule KinoProxy.TestHelpers do
  alias Livebook.Session

  import ExUnit.Assertions

  def insert_section(session_pid) do
    Session.insert_section(session_pid, 0)
    %{notebook: %{sections: [%{id: section_id} | _]}} = Session.get_data(session_pid)

    section_id
  end

  def insert_text_cell(session_pid, section_id, type, content \\ " ") do
    Session.insert_cell(session_pid, section_id, 0, type, %{source: content})

    {:ok, %{cells: [%{id: cell_id} | _]}} =
      Session.get_data(session_pid).notebook
      |> Livebook.Notebook.fetch_section(section_id)

    cell_id
  end

  def evaluate_setup(session_pid) do
    Session.queue_cell_evaluation(session_pid, "setup")
    assert_receive {:operation, {:add_cell_evaluation_response, _, "setup", _, _}}
  end
end
