-module(wsecli_framing_spec).
-include_lib("espec/include/espec.hrl").
-include_lib("hamcrest/include/hamcrest.hrl").
-include("wsecli.hrl").
%-compile([export_all]).

spec() ->
  describe("wsecli_framing", fun()->
        describe("to_binary", fun() ->
              describe("payload leng <= 125", fun()->
                    it("should return a binary representation of a frame", fun()->
                          Data = "Foo bar",


                          Frame = wsecli_framing:frame(Data),
                          BinFrame = wsecli_framing:to_binary(Frame),
                          <<
                          Fin:1,
                          Rsv1:1, Rsv2:1, Rsv3:1,
                          Opcode:4,
                          Mask:1,
                          PayloadLen:7,
                          MaskingKey:32,
                          Payload/binary
                          >> = BinFrame,

                          assert_that(Fin, is(Frame#frame.fin)),
                          assert_that(Rsv1, is(Frame#frame.rsv1)),
                          assert_that(Rsv2, is(Frame#frame.rsv2)),
                          assert_that(Rsv3, is(Frame#frame.rsv3)),
                          assert_that(Opcode, is(Frame#frame.opcode)),
                          assert_that(Mask, is(Frame#frame.mask)),
                          assert_that(PayloadLen, is(Frame#frame.payload_len)),
                          assert_that(MaskingKey, is(Frame#frame.masking_key)),
                          assert_that(Payload, is(Frame#frame.payload))
                      end)
                end),
              describe("payload length > 125 and <= 65536", fun() ->
                    it("should return a binary representation of a frame", fun()->
                          Data = get_random_string(165),


                          Frame = wsecli_framing:frame(Data),
                          BinFrame = wsecli_framing:to_binary(Frame),
                          <<
                          Fin:1,
                          Rsv1:1, Rsv2:1, Rsv3:1,
                          Opcode:4,
                          Mask:1,
                          PayloadLen:7,
                          ExtendedPayloadLen:16,
                          MaskingKey:32,
                          Payload/binary
                          >> = BinFrame,

                          assert_that(Fin, is(Frame#frame.fin)),
                          assert_that(Rsv1, is(Frame#frame.rsv1)),
                          assert_that(Rsv2, is(Frame#frame.rsv2)),
                          assert_that(Rsv3, is(Frame#frame.rsv3)),
                          assert_that(Opcode, is(Frame#frame.opcode)),
                          assert_that(Mask, is(Frame#frame.mask)),
                          assert_that(PayloadLen, is(Frame#frame.payload_len)),
                          assert_that(ExtendedPayloadLen, is(Frame#frame.extended_payload_len)),
                          assert_that(MaskingKey, is(Frame#frame.masking_key)),
                          assert_that(Payload, is(Frame#frame.payload))
                      end)
                end),
              describe("payloa length > 65536", fun() ->
                    it("should return a binary representation of a frame", fun()->
                          Data = get_random_string(78000),


                          Frame = wsecli_framing:frame(Data),
                          BinFrame = wsecli_framing:to_binary(Frame),
                          <<
                          Fin:1,
                          Rsv1:1, Rsv2:1, Rsv3:1,
                          Opcode:4,
                          Mask:1,
                          PayloadLen:7,
                          ExtendedPayloadLen:64,
                          MaskingKey:32,
                          Payload/binary
                          >> = BinFrame,

                          assert_that(Fin, is(Frame#frame.fin)),
                          assert_that(Rsv1, is(Frame#frame.rsv1)),
                          assert_that(Rsv2, is(Frame#frame.rsv2)),
                          assert_that(Rsv3, is(Frame#frame.rsv3)),
                          assert_that(Opcode, is(Frame#frame.opcode)),
                          assert_that(Mask, is(Frame#frame.mask)),
                          assert_that(PayloadLen, is(Frame#frame.payload_len)),
                          assert_that(ExtendedPayloadLen, is(Frame#frame.extended_payload_len_cont)),
                          assert_that(MaskingKey, is(Frame#frame.masking_key)),
                          assert_that(Payload, is(Frame#frame.payload))
                      end)
                end)
          end),
        describe("frame", fun() ->
              describe("when no options are passed", fun() ->
                    it("should unset fin", fun() ->
                          Frame = wsecli_framing:frame("Foo bar"),
                          assert_that(Frame#frame.fin, is(0))
                      end),
                    it("should set opcode to text on text data", fun()->
                          Frame = wsecli_framing:frame("Foo bar"),
                          assert_that(Frame#frame.opcode, is(1))
                      end),
                    it("should set opcode to binary on binary data", fun()->
                          Frame = wsecli_framing:frame(<<"Foo bar">>),
                          assert_that(Frame#frame.opcode, is(2))
                      end)
                end),
              describe("when options are passed", fun()->
                    it("should set fin if fin option is present", fun()->
                          Frame = wsecli_framing:frame("Foo bar", [fin]),
                          assert_that(Frame#frame.fin, is(1))
                      end),
                    it("should set opcode to text if opcode option is text", fun()->
                          Frame = wsecli_framing:frame("Foo bar", [{opcode, text}]),
                          assert_that(Frame#frame.opcode, is(1))
                      end),
                    it("should set opcode to binary if opcode option is binary", fun()->
                          Frame = wsecli_framing:frame("asdasdasd", [{opcode, binary}]),
                          assert_that(Frame#frame.opcode, is(2))
                      end),
                    it("should set opcode to ping if opcode option is ping", fun()->
                          Frame = wsecli_framing:frame("pinging", [{opcode, ping}]),
                          assert_that(Frame#frame.opcode, is(9))
                      end),
                    it("should set opcode to pong if opcode option is pong", fun() ->
                          Frame = wsecli_framing:frame("pingin", [{opcode, pong}]),
                          assert_that(Frame#frame.opcode, is(10))
                      end),
                    it("should set opcode to close if opcode option is close", fun() ->
                          % Notice that this is an invalid payload for a close frame
                          Frame = wsecli_framing:frame("closing", [{opcode, close}]),
                          assert_that(Frame#frame.opcode, is(8))
                      end),
                    it("should set opcode to continuation if opcode option is continuation", fun()->
                          Frame = wsecli_framing:frame("Foo bar", [{opcode, continuation}]),
                          assert_that(Frame#frame.opcode, is(0))
                      end)
                end),
              describe("text data", fun()->
                    %it("should set the FIN bit when the message is not fragmented", fun()->
                    %      Data = "Foo bar",

                    %      Frame = wsecli_framing:frame(Data),
                    %      assert_that(Frame#frame.fin, is(1))
                    %  end),
                    it("should leave the RSV bits unset", fun()->
                          Data = "Foo bar",
                          Frame = wsecli_framing:frame(Data),
                          assert_that(Frame#frame.rsv1, is(0)),
                          assert_that(Frame#frame.rsv2, is(0)),
                          assert_that(Frame#frame.rsv3, is(0))
                      end),
                    it("should set opcode to TEXT", fun() ->
                          Data = "Foo bar",

                          Frame = wsecli_framing:frame(Data),
                          assert_that(Frame#frame.opcode, is(1))
                      end),
                    describe("data length <= 125", fun() ->
                          it("should set data length in payload length", fun() ->
                                Data = "Foo bar",
                                Frame = wsecli_framing:frame(Data),
                                assert_that(Frame#frame.payload_len, is(string:len(Data)))
                            end),
                          it("should set 0 in extended payload length", fun()->
                                Data = "Foo bar",
                                Frame = wsecli_framing:frame(Data),
                                assert_that(Frame#frame.extended_payload_len, is(0))
                            end),
                          it("should set 0 in extended payload length cont.", fun()->
                                Data = "Foo bar",
                                Frame = wsecli_framing:frame(Data),
                                assert_that(Frame#frame.extended_payload_len_cont, is(0))
                            end)
                      end),
                    describe("data length > 125", fun() ->
                          it("should set in payload_len the value 126", fun() ->
                                Data = get_random_string(320),
                                Frame = wsecli_framing:frame(Data),
                                assert_that(Frame#frame.payload_len, is(126))
                            end),
                          it("should set data length in extended payload length", fun()->
                                Data = get_random_string(455),
                                Frame = wsecli_framing:frame(Data),
                                assert_that(Frame#frame.extended_payload_len, is(455))
                            end),
                          it("should set 0 in extended payload length cont.", fun()->
                                Data = "Foo bar",
                                Frame = wsecli_framing:frame(Data),
                                assert_that(Frame#frame.extended_payload_len_cont, is(0))
                            end)
                      end),
                    describe("data length > 65536", fun() ->
                          it("should set in payload_len the value 127", fun() ->
                                Data = get_random_string(70000),
                                Frame = wsecli_framing:frame(Data),
                                assert_that(Frame#frame.payload_len, is(127))
                            end),
                          it("should set 0 in extended payload length", fun()->
                                Data = get_random_string(68000),
                                Frame = wsecli_framing:frame(Data),
                                assert_that(Frame#frame.extended_payload_len, is(0))
                            end),
                          it("should set data length in extended payload length cont.", fun()->
                                Data = get_random_string(75000),
                                Frame = wsecli_framing:frame(Data),
                                assert_that(Frame#frame.extended_payload_len_cont, is(75000))
                            end)
                      end),
                    describe("masking", fun() ->
                          it("should set MASK", fun() ->
                                Data = "Foo bar",
                                Frame = wsecli_framing:frame(Data),
                                assert_that(Frame#frame.mask,is(1))
                            end),
                          it("should mask the payload", fun() ->
                                Data = "Foo bar",
                                BinData = list_to_binary(Data),
                                Frame = wsecli_framing:frame(Data),
                                MaskKey = Frame#frame.masking_key,
                                assert_that(Frame#frame.payload, is(mask(BinData, MaskKey, <<>>)))
                            end),
                          it("shouldn't affect payload length", fun() ->
                                Data = "Foo Bar",
                                BinData = list_to_binary(Data),
                                Frame = wsecli_framing:frame(Data),
                                assert_that(byte_size(Frame#frame.payload), is(byte_size(BinData)))
                            end)
                      end)
                end),
              %it("should set opcode to BINARY when data is binary", fun() ->
              %      Data = crypto:rand_bytes(64),

              %      Frame = wsecli_framing:frame(Data),
              %      assert_that(Frame#frame.opcode, is(2))
              %  end),
              describe("control frames", fun()->
                    it("should send connection close frames", fun() ->
                          Frame = wsecli_framing:control_frame({close, 1000, "Closing this shit"}),
                          %mask function also unmask the data
                          <<Code:16, Reason/binary>> = mask(
                            Frame#frame.payload,
                            Frame#frame.masking_key,
                            <<>>),

                          assert_that(Frame#frame.fin, is(1)),
                          assert_that(Frame#frame.rsv1, is(0)),
                          assert_that(Frame#frame.rsv2, is(0)),
                          assert_that(Frame#frame.rsv3, is(0)),
                          assert_that(Frame#frame.opcode, is(8)),
                          assert_that(Code, is(1000)),
                          assert_that(Frame#frame.mask, is(1)),
                          assert_that(binary_to_list(Reason), is("Closing this shit"))
                      end),
                    it("should send PING frames", fun() ->
                          Frame = wsecli_framing:control_frame({ping, "Andale"}),

                          MaskedData = mask(
                            list_to_binary("Andale"),
                            Frame#frame.masking_key,
                            <<>>),

                          assert_that(Frame#frame.fin, is(1)),
                          assert_that(Frame#frame.rsv1, is(0)),
                          assert_that(Frame#frame.rsv2, is(0)),
                          assert_that(Frame#frame.rsv3, is(0)),
                          assert_that(Frame#frame.opcode, is(9)),
                          assert_that(Frame#frame.mask, is(1)),
                          assert_that(Frame#frame.payload, is(MaskedData))
                      end),
                    it("should send PONG frames", fun() ->
                          Frame = wsecli_framing:control_frame({pong, "Andale"}),

                          MaskedData = mask(
                            list_to_binary("Andale"),
                            Frame#frame.masking_key,
                            <<>>),

                          assert_that(Frame#frame.fin, is(1)),
                          assert_that(Frame#frame.rsv1, is(0)),
                          assert_that(Frame#frame.rsv2, is(0)),
                          assert_that(Frame#frame.rsv3, is(0)),
                          assert_that(Frame#frame.opcode, is(10)),
                          assert_that(Frame#frame.mask, is(1)),
                          assert_that(Frame#frame.payload, is(MaskedData))
                      end)
                end),
              it("should fragmen messages")
          end)
    end).

get_random_string(Length) ->
  AllowedChars = "qwertyQWERTY1234567890",
  lists:foldl(fun(_, Acc) ->
        [lists:nth(random:uniform(length(AllowedChars)),
            AllowedChars)]
        ++ Acc
    end, [], lists:seq(1, Length)).

%mask(Bin, MaskKey, Acc) ->
mask(<<Data:32, Rest/bits>>, MaskKey, Acc) ->
  T = Data bxor MaskKey,
  mask(Rest, MaskKey, <<Acc/binary, T:32>>);

mask(<< Data:24>>, MaskKey, Acc) ->
  <<MaskKey2:24, _/bits>> = <<MaskKey:32>>,
  T = Data bxor MaskKey2,
  <<Acc/binary, T:24>>;

mask(<< Data:16>>, MaskKey, Acc) ->
  <<MaskKey2:16, _/bits>> = <<MaskKey:32>>,
  T = Data bxor MaskKey2,
  <<Acc/binary, T:16>>;

mask(<< Data:8>>, MaskKey, Acc) ->
  <<MaskKey2:8, _/bits>> = <<MaskKey:32>>,
  T = Data bxor MaskKey2,
  <<Acc/binary, T:8>>;

mask(<<>>, _, Acc) ->
  Acc.
