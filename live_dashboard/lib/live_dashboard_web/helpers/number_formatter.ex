defmodule LiveDashboardWeb.NumberFormatter do
  def format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.replace(~r/(\d)(?=(\d{3})+(?!\d))/, "\\1 ")
  end

  def format_number(number), do: number
end
