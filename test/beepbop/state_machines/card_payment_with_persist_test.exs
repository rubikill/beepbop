defmodule BeepBop.Example.CardPaymentMachineTest do
  defstruct [:dummy]

  use ExUnit.Case, async: true

  alias BeepBop.Example.CardPayment
  alias BeepBop.Example.CardPaymentMachine, as: Machine

  @states ~w[pending authorized captured refunded voided failed]a
  @events ~w[authorize]a

  test "metadata" do
    assert Machine.__beepbop__(:module) == BeepBop.Example.CardPayment
    assert Machine.__beepbop__(:column) == :status
    assert Machine.__beepbop__(:name) == :card_payment
    assert Machine.__beepbop__(:repo) == BeepBop.TestRepo
    assert @events = Machine.__beepbop__(:events)
    assert @states = Machine.__beepbop__(:states)

    assert %{
             authorize: %{from: [:pending], to: :authorized}
           } = Machine.__beepbop__(:transitions)
  end

  test "context validator" do
    assert Machine.valid_context?(BeepBop.Context.new(%CardPayment{}))

    refute Machine.valid_context?(%{})
    refute Machine.valid_context?(BeepBop.Context.new(%CardPayment{}, valid?: false))
    refute Machine.valid_context?(BeepBop.Context.new(%__MODULE__{}))
  end

  test "transition validator" do
    assert Machine.can_transition?(BeepBop.Context.new(%CardPayment{}), :authorize)
    refute Machine.can_transition?(BeepBop.Context.new(%CardPayment{status: "lol"}), :authorize)

    refute Machine.can_transition?(
             %BeepBop.Context{struct: %CardPayment{}, valid?: false},
             :authorize
           )
  end

  test "persistor: module with persist/2" do
    assert :ok = Machine.__persistor_check__()
  end
end
