defmodule Identicon do
  @typedoc """
    Type that represents the main data schema from Identicon Module: Identicon.Image
  """
  @type rgb :: {pos_integer,pos_integer,pos_integer}
  @type hex_codes :: [pos_integer, ...]
  @type grid :: [{pos_integer,pos_integer}, ...]
  @type point :: {integer, integer}
  @type image :: %Identicon.Image{hex: hex_codes, color: rgb | nil, grid: grid | nil, pixels: [{point, point}, ...] | nil}


  @spec main(charlist) :: :ok
  def main(input) do
    input |> hash_input |> pick_color |> build_grid |> filter_odd_squares |> build_pixel_map |> draw_image |> save_image(input)
  end

  @spec hash_input(charlist) :: image
  def hash_input(input) do
    hex = :crypto.hash(:md5, input) |>
    :binary.bin_to_list()

    %Identicon.Image{hex: hex}
  end

  @spec pick_color(image) :: image
  def pick_color(%Identicon.Image{hex: [r,g,b | _tail]} = image) do

    %Identicon.Image{image | color: {r,g,b}}
  end

  @spec build_grid(image) :: image
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid = hex |> Enum.chunk_every(3, 3, :discard) |> Enum.map(&mirror_row/1) |> List.flatten |> Enum.with_index

    %Identicon.Image{image | grid: grid}
  end

  @spec mirror_row(row :: hex_codes) :: hex_codes
  def mirror_row([first, second | _tail] = row) do
    row ++ [second, first]
  end

  @spec filter_odd_squares(image) :: image
  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = Enum.filter(grid, fn ({hex, _index}) -> rem(hex,2) == 0  end)

    %Identicon.Image{image | grid: grid}
  end


  @spec build_pixel_map(image) :: image
  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixels = Enum.map(grid, fn ({_hex, index}) ->
      x = rem(index, 5) * 50
      y = div(index, 5) * 50
      top_left= {x, y}
      bottom_right = {x+50, y+50}
      {top_left, bottom_right}
    end)
    %Identicon.Image{image | pixels: pixels}
  end

  @spec draw_image(image) :: binary
  def draw_image(%Identicon.Image{color: color, pixels: pixels}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixels, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end)

    :egd.render(image)
  end

  @spec save_image(image :: binary, filename :: charlist) :: :ok
  def save_image(image, filename) do
    File.write("#{filename}.png", image)
  end

end
