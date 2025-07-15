defmodule RaBackendWeb.LabelJSON do
  @doc """
  Renders a list of labels.
  """
  def index(%{labels: labels}) do
    %{data: for(label <- labels, do: data(label))}
  end

  @doc """
  Renders a single label.
  """
  def data(%RaBackend.GraLabels.GraLabel{} = label) do
    %{
      id: label.id,
      name: label.name,
      description: label.description,
      category: label.category,
      subcategory: label.subcategory,
      color: label.color,
      icon: label.icon,
      priority: label.priority,
      metadata: label.metadata,
      created_by: user_data(label.created_by_user),
      updated_by: user_data(label.updated_by_user),
      inserted_at: label.inserted_at,
      updated_at: label.updated_at
    }
  end

  defp user_data(nil), do: nil
  defp user_data(user) do
    %{
      id: user.id,
      name: user.name
    }
  end
end
