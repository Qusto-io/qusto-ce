defmodule Plausible.Ingestion.IPMaskTest do
  use ExUnit.Case, async: true

  alias Plausible.Ingestion.IPMask

  describe "mask/1" do
    test "IPv4 keeps the first three octets (/24)" do
      assert IPMask.mask("93.184.216.34") == "93.184.216.0"
    end

    test "IPv6 keeps the first 48 bits (/48)" do
      assert IPMask.mask("2001:db8:abcd:12:1:2:3:4") == "2001:db8:abcd::"
    end

    # /48 of ::ffff:a.b.c.d is "::" for every IPv4 visitor, which would merge
    # them all into one key; the embedded IPv4 address is masked to /24 instead.
    test "IPv4-mapped IPv6 is masked as its IPv4 address (/24)" do
      assert IPMask.mask("::ffff:93.184.216.34") == "93.184.216.0"
    end

    test "a value that is not an IP is returned unchanged" do
      assert IPMask.mask("not-an-ip") == "not-an-ip"
      assert IPMask.mask("") == ""
    end
  end

  describe "hash_ip/2" do
    setup do
      previous = Application.get_env(:plausible, IPMask)
      Application.put_env(:plausible, IPMask, domains: MapSet.new(["negozio.it"]))
      on_exit(fn -> Application.put_env(:plausible, IPMask, previous || []) end)
    end

    test "masks for a listed domain" do
      assert IPMask.hash_ip("93.184.216.34", "negozio.it") == "93.184.216.0"
    end

    test "is the identity for any other domain" do
      assert IPMask.hash_ip("93.184.216.34", "shop.example") == "93.184.216.34"
    end
  end
end
