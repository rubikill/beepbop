defmodule BeepBop do
  defmacro __using__(opts) do
    unless Keyword.has_key?(opts, :ecto_repo) do
      raise(ArgumentError, message: ~s{

Please configure an Ecto.Repo by passing an Ecto.Repo like so:
    use BeepBop, ecto_repo: YourProject.Repo
})
    end

    quote do
      import BeepBop
      alias Ecto.Multi

      @repo_opts nil
      
      defp _beepbop_repo do
        Keyword.fetch!(unquote(opts), :ecto_repo)
      end
    end
  end

  defmacro state_machine(schema, column, do: block) do
    quote location: :keep do
      if @repo_opts == nil, do: @repo_opts([])

      defp _beepbop_state_column, do: unquote(column)
      defp _beepbop_schema, do: unquote(schema)

      unquote(block)
    end
  end

  defmacro states(states) do
    quote do
      def states() do
        unquote(states)
      end

      def state_defined?(state) do
        Enum.member?(states(), state)
      end
    end
  end

  defmacro event(event, options, callback) do
    quote location: :keep do

      @doc """
      Runs the defined callback.

      This function was generated by the `BeepBop.event/3` macro.
      """
      @spec unquote(event)(map, keyword) :: {:ok, map | struct} | {:error, term}
      def unquote(event)(context, opts \\ []) do
        persist? = Keyword.get(opts, :persist, true)
        repo_opts = Keyword.get(opts, :repo, [])
        %{from: from_states, to: to_state} = unquote(options)

        param =
          case context do
            %BeepBop.State{} = context -> context
            %{} = context -> BeepBop.State.new(context)
          end

        {status, state_struct} = result = unquote(callback).(param)

        if status == :ok and persist? do
          repo = _beepbop_repo()
          repo.transaction(state_struct.multi, @repo_opts)
        else
          result
        end
      end
    end
  end
end
