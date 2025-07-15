defmodule RaBackendWeb.CharacterController do
  use RaBackendWeb, :controller

  alias RaBackend.GraCharacters

  def create_empty(conn, %{"user_uid" => user_uid}) do
    case GraCharacters.create_empty_character(user_uid) do
      {:ok, character} ->
        conn
        |> put_status(:created)
        |> json(%{
          graCharacterId: character.id  # Use camelCase to match Swift
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def update_with_labels(conn, %{"id" => character_id} = params) do
    # Extract label_ids and other attributes
    attrs = Map.take(params, ["name", "biography", "system_prompt", "creation_prompt", "llm_model", "is_public"])
    |> Map.put("label_ids", params["label_ids"] || [])

    case GraCharacters.update_character_with_labels(character_id, attrs) do
      {:ok, character} ->
        conn
        |> json(%{
          gra_character_id: character.id,
          name: character.name,
          biography: character.biography,
          system_prompt: character.system_prompt,
          creation_prompt: character.creation_prompt,
          llm_model: character.llm_model,
          is_public: character.is_public,
          metadata: character.metadata
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def show(conn, %{"id" => character_id}) do
    character = GraCharacters.get_character_with_relationships(character_id)

    conn
    |> json(%{
      gra_character_id: character.id,
      name: character.name,
      biography: character.biography,
      system_prompt: character.system_prompt,
      creation_prompt: character.creation_prompt,
      llm_model: character.llm_model,
      is_public: character.is_public,
      metadata: character.metadata,
      labels: Enum.map(character.labels, &%{id: &1.id, name: &1.name}),
      handle: if(character.unique_handle, do: %{handle_name: character.unique_handle.handle_name})
    })
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
