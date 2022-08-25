defmodule Flop.Operators do
  @moduledoc false

  import Ecto.Query

  defmacro build_dynamic(fragment, binding?, _combinator = nil) do
    binding_arg = binding_arg(binding?)

    quote do
      dynamic(unquote(binding_arg), ^var!(c) and unquote(fragment))
    end
  end

  defmacro build_dynamic(fragment, binding?, :and) do
    binding_arg = binding_arg(binding?)

    quote do
      filter_condition =
        Enum.reduce(var!(value), true, fn substring, dynamic ->
          dynamic(unquote(binding_arg), ^dynamic and unquote(fragment))
        end)

      dynamic(unquote(binding_arg), ^var!(c) and ^filter_condition)
    end
  end

  defmacro build_dynamic(fragment, binding?, :or) do
    binding_arg = binding_arg(binding?)

    quote do
      filter_condition =
        Enum.reduce(var!(value), false, fn substring, dynamic ->
          dynamic(unquote(binding_arg), ^dynamic or unquote(fragment))
        end)

      dynamic(unquote(binding_arg), ^var!(c) and ^filter_condition)
    end
  end

  defp binding_arg(true) do
    quote do
      [{^var!(binding), r}]
    end
  end

  defp binding_arg(false) do
    quote do
      [r]
    end
  end

  def op_config(:==) do
    fragment =
      quote do
        field(r, ^var!(field)) == ^var!(value)
      end

    {fragment, nil, nil}
  end

  def op_config(:!=) do
    fragment =
      quote do
        field(r, ^var!(field)) != ^var!(value)
      end

    {fragment, nil, nil}
  end

  def op_config(:>=) do
    fragment =
      quote do
        field(r, ^var!(field)) >= ^var!(value)
      end

    {fragment, nil, nil}
  end

  def op_config(:<=) do
    fragment =
      quote do
        field(r, ^var!(field)) <= ^var!(value)
      end

    {fragment, nil, nil}
  end

  def op_config(:>) do
    fragment =
      quote do
        field(r, ^var!(field)) > ^var!(value)
      end

    {fragment, nil, nil}
  end

  def op_config(:<) do
    fragment =
      quote do
        field(r, ^var!(field)) < ^var!(value)
      end

    {fragment, nil, nil}
  end

  def op_config(:empty) do
    fragment = empty()
    {fragment, nil, nil}
  end

  def op_config(:not_empty) do
    fragment =
      quote do
        not unquote(empty())
      end

    {fragment, nil, nil}
  end

  def op_config(:in) do
    fragment =
      quote do
        field(r, ^var!(field)) in ^var!(value)
      end

    {fragment, nil, nil}
  end

  def op_config(:contains) do
    fragment =
      quote do
        ^var!(value) in field(r, ^var!(field))
      end

    {fragment, nil, nil}
  end

  def op_config(:not_contains) do
    fragment =
      quote do
        ^var!(value) not in field(r, ^var!(field))
      end

    {fragment, nil, nil}
  end

  def op_config(:like) do
    fragment =
      quote do
        like(field(r, ^var!(field)), ^var!(value))
      end

    prelude = prelude(:add_wildcard)
    {fragment, prelude, nil}
  end

  def op_config(:=~) do
    fragment =
      quote do
        ilike(field(r, ^var!(field)), ^var!(value))
      end

    prelude = prelude(:add_wildcard)
    {fragment, prelude, nil}
  end

  def op_config(:ilike) do
    fragment =
      quote do
        ilike(field(r, ^var!(field)), ^var!(value))
      end

    prelude = prelude(:add_wildcard)
    {fragment, prelude, nil}
  end

  def op_config(:not_in) do
    fragment =
      quote do
        field(r, ^var!(field)) not in ^var!(processed_value) and
          not (^var!(reject_nil?) and is_nil(field(r, ^var!(field))))
      end

    prelude =
      quote do
        var!(reject_nil?) = nil in var!(value)

        var!(processed_value) =
          if var!(reject_nil?),
            do: Enum.reject(var!(value), &is_nil(&1)),
            else: var!(value)
      end

    {fragment, prelude, nil}
  end

  def op_config(:like_and) do
    fragment =
      quote do
        like(field(r, ^var!(field)), ^substring)
      end

    prelude = prelude(:split_search_text)
    combinator = :and

    {fragment, prelude, combinator}
  end

  def op_config(:like_or) do
    fragment =
      quote do
        like(field(r, ^var!(field)), ^substring)
      end

    prelude = prelude(:split_search_text)
    combinator = :or

    {fragment, prelude, combinator}
  end

  def op_config(:ilike_and) do
    fragment =
      quote do
        ilike(field(r, ^var!(field)), ^substring)
      end

    prelude = prelude(:split_search_text)
    combinator = :and

    {fragment, prelude, combinator}
  end

  def op_config(:ilike_or) do
    fragment =
      quote do
        ilike(field(r, ^var!(field)), ^substring)
      end

    prelude = prelude(:split_search_text)
    combinator = :or

    {fragment, prelude, combinator}
  end

  defp empty do
    quote do
      is_nil(field(r, ^var!(field))) == ^var!(value)
    end
  end

  defp prelude(:add_wildcard) do
    quote do
      var!(value) = Flop.Misc.add_wildcard(var!(value))
    end
  end

  defp prelude(:split_search_text) do
    quote do
      var!(value) = Flop.Misc.split_search_text(var!(value))
    end
  end
end