@Tags(['integration'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

Matcher isWithinRange(int lower, int upper) => predicate(
    (x) => x is num && x >= lower && x <= upper,
    'is within range $lower to $upper');

void main() async {
  group('P2WPKH fee estimation', () {
    late SingleSignatureVault vault;
    late SingleSignatureWallet wallet;
    setUpAll(() async {
      BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
      vault = SingleSignatureVault.fromMnemonic(
          'output opera coin bottom power cable abuse bitter maximum cost gift burger',
          AddressType.p2wpkh);

      wallet = SingleSignatureWallet.fromDescriptor(vault.descriptor);
      NodeConnector nodeConnector = await NodeConnector.connectSync(
          'regtest-electrum.coconut.onl', 60401,
          ssl: true);

      /// fetch on chain data
      await wallet.fetchOnChainData(nodeConnector);
    });

    test('1 input, 2 outputs', () {
      String unsignedPsbtText =
          'cHNidP8BAH0CAAAAAS9g0/TjpIqS/Ale5z4vde1iqMbeKCnrZvW9+YuUZ+l4AQAAAAD/////AjB1AAAAAAAAIgAgtM9+myvnkbtyoKf5uDyMOk9RZqLUESQYGrOeKgBpGmzBG/kCAAAAABYAFKWQOOXmKcnJd6ikKx4fdYaVwsUEAAAAAAABAR+KkfkCAAAAABYAFAmlBdyu41TkvK2AfF5XunnFNOi5IgYDnQWmZ21aozZGWQg50ezr/2X9tObqI8GSfpcIl4c/A9AYBRCYxFQAAIABAACAAAAAgAEAAAAKAAAAAAEDBDB1AAABBCMiACC0z36bK+eRu3Kgp/m4PIw6T1FmotQRJBgas54qAGkabAABAwTBG/kCAQQXFgAUpZA45eYpycl3qKQrHh91hpXCxQQiAgKXnAFgb7ilepm1fpyaMMWOio28bw90vigs6sBIqB7SixgFEJjEVAAAgAEAAIAAAACAAQAAAAsAAAAAAA==';
      String signedPsbtText =
          'cHNidP8BAH0CAAAAAS9g0/TjpIqS/Ale5z4vde1iqMbeKCnrZvW9+YuUZ+l4AQAAAAD/////AjB1AAAAAAAAIgAgtM9+myvnkbtyoKf5uDyMOk9RZqLUESQYGrOeKgBpGmzBG/kCAAAAABYAFKWQOOXmKcnJd6ikKx4fdYaVwsUEAAAAAAABAR+KkfkCAAAAABYAFAmlBdyu41TkvK2AfF5XunnFNOi5IgYDnQWmZ21aozZGWQg50ezr/2X9tObqI8GSfpcIl4c/A9AYBRCYxFQAAIABAACAAAAAgAEAAAAKAAAAIgIDnQWmZ21aozZGWQg50ezr/2X9tObqI8GSfpcIl4c/A9BHMEQCIHGFPakG2HaGi8zljH4XWSLQgN57Wt9/37YSO+XE1I83AiBoGseHZf0XxVVUTXuZoqY1n6eIVng+YNB7Uc6q+tq5KAEAAQMEMHUAAAEEIyIAILTPfpsr55G7cqCn+bg8jDpPUWai1BEkGBqznioAaRpsAAEDBMEb+QIBBBcWABSlkDjl5inJyXeopCseH3WGlcLFBCICApecAWBvuKV6mbV+nJowxY6KjbxvD3S+KCzqwEioHtKLGAUQmMRUAACAAQAAgAAAAIABAAAACwAAAAAA';
      int expectFee = 153;
      PSBT unsignedPSBT = PSBT.parse(unsignedPsbtText);
      PSBT signedPSBT = PSBT.parse(signedPsbtText);
      expect(unsignedPSBT.estimateFee(1, AddressType.p2wpkh),
          expectFee); // estimate unsigned psbt
      expect(signedPSBT.estimateFee(1, AddressType.p2wpkh),
          expectFee); // estimate signed psbt
      expect(signedPSBT.fee, expectFee); // real output fee

      Transaction tx = signedPSBT.getSignedTransaction(wallet.addressType);
      // txid :  c39ca53e6dc71641f684a10ac8258aa323f6a7d9db414a130788925c21920d49

      expect(tx.estimateFee(1, AddressType.p2wpkh),
          expectFee); // estimate transaction without witness
    });

    test('3 input, 1 outputs', () {
      String unsignedPsbtText =
          'cHNidP8BALACAAAAA0kNkiFckogHE0pB29mn9iOjiiXICqGE9kEWx20+pZzDAQAAAAD/////IeitUhpT0dc+0ZDXRV1V5Yai6z4XehAsMs6sjGJ4m9sAAAAAAP/////JKqN07nNcPIZ+2u8lk4YnWGgcM0H+0yJT3hPDush/bwAAAAAA/////wH/OfkCAAAAACIAILTPfpsr55G7cqCn+bg8jDpPUWai1BEkGBqznioAaRpsAAAAAAABAR/BG/kCAAAAABYAFKWQOOXmKcnJd6ikKx4fdYaVwsUEIgYCl5wBYG+4pXqZtX6cmjDFjoqNvG8PdL4oLOrASKge0osYBRCYxFQAAIABAACAAAAAgAEAAAALAAAAAAEBH6APAAAAAAAAFgAUlioXqG/x1MpFWpRnLOeYzD5PBmMiBgO4mt3t0JFwnXEAGTYBO+fsGACgTVaHVZjIBoOammi+MBgFEJjEVAAAgAEAAIAAAACAAAAAAAEAAAAAAQEfoA8AAAAAAAAWABSWKheob/HUykValGcs55jMPk8GYyIGA7ia3e3QkXCdcQAZNgE75+wYAKBNVodVmMgGg5qaaL4wGAUQmMRUAACAAQAAgAAAAIAAAAAAAQAAAAABAwT/OfkCAQQjIgAgtM9+myvnkbtyoKf5uDyMOk9RZqLUESQYGrOeKgBpGmwAAA==';
      String signedPsbtText =
          'cHNidP8BALACAAAAA0kNkiFckogHE0pB29mn9iOjiiXICqGE9kEWx20+pZzDAQAAAAD/////IeitUhpT0dc+0ZDXRV1V5Yai6z4XehAsMs6sjGJ4m9sAAAAAAP/////JKqN07nNcPIZ+2u8lk4YnWGgcM0H+0yJT3hPDush/bwAAAAAA/////wH/OfkCAAAAACIAILTPfpsr55G7cqCn+bg8jDpPUWai1BEkGBqznioAaRpsAAAAAAABAR/BG/kCAAAAABYAFKWQOOXmKcnJd6ikKx4fdYaVwsUEIgYCl5wBYG+4pXqZtX6cmjDFjoqNvG8PdL4oLOrASKge0osYBRCYxFQAAIABAACAAAAAgAEAAAALAAAAIgICl5wBYG+4pXqZtX6cmjDFjoqNvG8PdL4oLOrASKge0otHMEQCIDIZwQfWEU7qIYzKjLGgjHX0AFvL11/2TbkcSUzAcXttAiBpmc+arEMQy7cb8I3o5TLmoTOyHy+jri6NiA5ZVPFI6QEAAQEfoA8AAAAAAAAWABSWKheob/HUykValGcs55jMPk8GYyIGA7ia3e3QkXCdcQAZNgE75+wYAKBNVodVmMgGg5qaaL4wGAUQmMRUAACAAQAAgAAAAIAAAAAAAQAAACICA7ia3e3QkXCdcQAZNgE75+wYAKBNVodVmMgGg5qaaL4wRzBEAiBtfsqjB/oPpUuRkAVTYDfafi4nXahcg/XQ7tIp+sAatwIgEkvrxR5dvfONZuIUmYnrNQTPNLmtNVjF+iUi1pTb+IsBAAEBH6APAAAAAAAAFgAUlioXqG/x1MpFWpRnLOeYzD5PBmMiBgO4mt3t0JFwnXEAGTYBO+fsGACgTVaHVZjIBoOammi+MBgFEJjEVAAAgAEAAIAAAACAAAAAAAEAAAAiAgO4mt3t0JFwnXEAGTYBO+fsGACgTVaHVZjIBoOammi+MEcwRAIgYO9TKma4jNSKFUx1oq1MQ8eaV52ogfSj7Yy5nX2zfjwCIEVLiU0nsNTgfMyX9Z/O6oeJchVxMXK9YTe2Vr3KCTTaAQABAwT/OfkCAQQjIgAgtM9+myvnkbtyoKf5uDyMOk9RZqLUESQYGrOeKgBpGmwAAA==';
      int expectFee = 258;

      PSBT unsignedPSBT = PSBT.parse(unsignedPsbtText);
      PSBT signedPSBT = PSBT.parse(signedPsbtText);
      // print(unsignedPSBT.estimateFee(1, AddressType.p2wpkh));
      // print(signedPSBT.estimateFee(1, AddressType.p2wpkh));
      // print(signedPSBT.fee);
      expect(unsignedPSBT.estimateFee(1, AddressType.p2wpkh),
          isWithinRange(expectFee - 2, expectFee + 2));
      expect(signedPSBT.estimateFee(1, AddressType.p2wpkh),
          isWithinRange(expectFee - 2, expectFee + 2));
      expect(signedPSBT.fee, isWithinRange(expectFee - 2, expectFee + 2));

      Transaction tx = signedPSBT.getSignedTransaction(wallet.addressType);
      // txid : 7ecd227bfd9565be03e38d1942582f0525c4ec353a0287298cd9cbdc4acbade2
      // print(tx.inputs.length);
      // print(tx.outputs.length);

      // print(tx.estimateFee(1, AddressType.p2wpkh));
      // print(tx.calculateFee(1));

      expect(tx.estimateFee(1, AddressType.p2wpkh),
          isWithinRange(expectFee - 2, expectFee + 2));
    });
  });

  group('P2WSH fee estimation', () {
    late MultisignatureWallet wallet;
    setUpAll(() async {
      BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
      wallet = MultisignatureWallet.fromDescriptor(
          "wsh(sortedmulti(2,[AEF5B293/48'/1'/0'/2']Vpub5nPUGCe9LkKe84RidJpnT4PXxqFCMnp7MFBvksxDAvKGQMuBaCnrS72AXwoWM6JmvDfAdUoAiRPHwAFTP2RvE5kLgkcyMRjgHAqWVkEdWPb/<0;1>/*,[BAD41B33/48'/1'/0'/2']Vpub5mQcGAR1SLrnugDSZ8GNVCwgJZJfYgR9TMpJxoQw4mHnQm9FC7JXjuCZbnf9wjiLzsmnWKA3fQCZ68JqntXYwGBrNc8zRCEeUcHXu9Bs9ZY/<0;1>/*,[62A936C3/48'/1'/0'/2']Vpub5nJPDy5rAwoiBH3yiGuABQT8KXzfiq1YWexHeYs3RN2vui8Whp3JsqbWjiEqN5joJWMH7jsjp81CD8AZsaNGhd6DrdNUTneAEEBDaXt1N5d/<0;1>/*))#9kvgyuj4");

      /// fetch on chain data
    });

    test('expect vertual byte', () {
      double expectedVByte = 188.75;
      Transaction tx = Transaction.forSending([
        TransactionInput.forSending(
            'e72de6706e380d1a0c984b0ddb75dadca932ab9bef641343353b1204c4d473c9',
            0)
      ], [
        TransactionOutput.forSending(
            4000, 'bcrt1qjc4p02r0782v5326j3njeeucesly7pnrwnaqft'),
        TransactionOutput.forSending(49883282,
            'bcrt1q4jp4x0wz5z5zelajmve9dmm3llds2k5q057gnnlz4nam0hje6lrsx95yv2')
      ], AddressType.p2wsh);
      expect(
          tx.estimateVirtualByte(AddressType.p2wsh,
              requiredSignature: 2, totalSigner: 3),
          isWithinRange(expectedVByte.floor() - 1, expectedVByte.ceil() + 1));
    });

    test('expect vertual byte(maximum)', () async {
      // txid : 4e13fd3eda84afd6b6521013fa7bc06d3bd2db2764b8455d8da0829bc6f36d2a
      double expectedVByte = 771.5;

      String txText =
          '02000000000107c973d4c404123b35431364ef9bab32a9dcda75db0d4b980c1a0d386e70e62de70100000000ffffffff490d92215c928807134a41dbd9a7f623a38a25c80aa184f64116c76d3ea59cc30000000000ffffffff2f60d3f4e3a48a92fc095ee73e2f75ed62a8c6de2829eb66f5bdf98b9467e9780000000000ffffffff21e8ad521a53d1d73ed190d7455d55e586a2eb3e177a102c32ceac8c62789bdb0100000000ffffffff154b11541b049bd9ed84248c68f5279b9606b55740e000853e6644a773c57b0f0000000000ffffffff680d46e2c2ca723b1ef908dc4d660aa1e13aaf197121216d7ea0ebdff13c69ea0000000000ffffffffc92aa374ee735c3c867edaef2593862758681c3341fed32253de13c3bac87f6f0100000000ffffffff019b395c0500000000160014962a17a86ff1d4ca455a94672ce798cc3e4f06630400483045022100dc8b2a32809919c32631a1c3af43d1f0489401bb869b775dd6f6f4ef413af1ed022038b58f0dea1cd020ffcf060dd978d6e791a386a12ff3588d30440f48bb6b59a001473044022009817e2d495cbe35227936aada5d3abe0dd38c23ba83586ea25523af2a08b1df022050291a3bd7a205a810d420d498532f16e7cca8933e777249265bd23c3f854454016952210293a10bb06b9d6be32e8adb0a2b832f40c2d1b63a78c2520bcfbd46141f9e04d421020e4ec1a899f2326baf29103922e6fb1ce30a690010539774d242238da806399a2103d68d2d76cdaba22c422391421cca8ba132a73d5dd87fc679348808e4c1897cd353ae040047304402202430375f00d1bc8ac5c98bd62a6e060367c301ac09189c3d396547b4e72ca76c02205c6d074772fe55334f1d3757722a8b1ee8a17e86d495732e29b0404f249f264b01483045022100c649fbf4044a6bcf0b1fb104d94b2aa555669bb135e90d238cf22eef997cec110220660b84e7da1f932548599ead3585216aa54b4532f9df25d6a8d50b18ccc64d920169522102e639419a5e796a0fb6aec2c5a0a5d74416ea405c27ed2ceed48121b7aedefa5621032e88ef30f5316cf0ef753894287f01570250adbb62de502035e0ce7c7a802fda2103d46417aa41ce16b5ad0ddc7144f4b3acf12cb4ad0b20c75dc17410394f97950453ae0400483045022100eb6f0ea2f4181fe0c50b4b318460a2cfbc7444ecf7740f78bb254e9c8cd3746f02202fe012a9b3f04869bbecb7e0e2801df3ef08e8a53a5ec95462116375f31d8e36014730440220700a53edfdc709478dfaa1f26d55605675449e69114a91c358b8990c5d57664002201f4e55dea5bd49ca876eaee1c7732b8bab87e7a0a6ea9bfa646065dcd7a48d460169522102e639419a5e796a0fb6aec2c5a0a5d74416ea405c27ed2ceed48121b7aedefa5621032e88ef30f5316cf0ef753894287f01570250adbb62de502035e0ce7c7a802fda2103d46417aa41ce16b5ad0ddc7144f4b3acf12cb4ad0b20c75dc17410394f97950453ae04004730440220188534572077dc3bbc56e84b861acb9a90134711342c5c273dca427a240cd4aa02202821b8b83da96f9ca830fbead574801392adc93585b526f56f775da4aaa1671e01483045022100db09272a666268632570ceb784e2d9f09dae5c2c14f2f9ddeb5c8096f23ca76702206ccd8f1b0135393299583fac71fbe7a05d1c225a3db3d934ae4a0974ebecce9001695221027f2ee9ca303df845383483f2e44e871e7f5fab8bd955048c25138b5c05b25e992102de034d450ff0b3b7e198fb8f3766e9072dc94ecbe85b68dd28b7557083c2fb232102c44425b4e2f28742a1968e6598ae9abcf9674120adf9fa21245edfe1a9d2c65d53ae04004830450221008abf1df4aa1f711f64d62fb3900a00918848e7f101de8f03705ac35cffefa3f402205d3ff2d0cd96e8d9ee71cd7378da74d7b42aa91d2f69233c69a67410cf954c7101483045022100fee93159a04d0764f6fc5d454726cc84f6acbc7c564c48c316b3a193ae98ba16022077f6278c790e0b36b63a3c59567eee22505ce380ea5dd1d3af8e608c3dad93200169522102e639419a5e796a0fb6aec2c5a0a5d74416ea405c27ed2ceed48121b7aedefa5621032e88ef30f5316cf0ef753894287f01570250adbb62de502035e0ce7c7a802fda2103d46417aa41ce16b5ad0ddc7144f4b3acf12cb4ad0b20c75dc17410394f97950453ae0400483045022100917580bb57b5f5beda0abd5195b138e7e283539d58c573475baa3a39922f6036022079b8d00ec34f84e1aaabe49f018d194b0d2d7148dfa8b0e2a43984ea714cc72d01473044022013e277f8de2edf33b3e571cd680ccee6686275511d38a261dd9c13b4785da0a50220484f8430bf6c1649ef124779420f34feead2d720ffc33faa673954ce370503c80169522102e639419a5e796a0fb6aec2c5a0a5d74416ea405c27ed2ceed48121b7aedefa5621032e88ef30f5316cf0ef753894287f01570250adbb62de502035e0ce7c7a802fda2103d46417aa41ce16b5ad0ddc7144f4b3acf12cb4ad0b20c75dc17410394f97950453ae040047304402206cd82b34073aec191b2264d002ecba06a8efb201216a2d6e4efa78ceecb0bd7002203a23f505d540bb6421dd8277cd51c428aa90571e0b6ffa710b1f33c7a3dc4d5e01483045022100986f64de13b750624d5d07977d7a2e6784b2b6711e5dd1c052cd8df38349850e02201c7a23e31539a4a8c8e9fb05fabff28018e9608477500b83626521fec852e09f0169522103525b642f33199f8adb34c611432158bbfd885c5bed5719e9bc85ba9580bea66821038af6b25b2428600d09f3a9a61cdff43bbe4d76d6ca6cb4f77e0d195007cbc56a210381e1e7501e9a816c4646a012e73500b6524c5249e4d349d18784782d542abb9653ae00000000';
      Transaction tx = Transaction.parse(txText);

      // print(tx.estimateVirtualByte(AddressType.p2wsh,
      //     requiredSignature: 2, totalSigner: 3));

      for (TransactionInput txin in tx.inputs) {
        txin.witnessList = [];
      }

      expect(
          tx.estimateVirtualByte(AddressType.p2wsh,
              requiredSignature: 2, totalSigner: 3),
          expectedVByte);
    });

    test('1 input, 2 outputs ', () {
      //txid : e72de6706e380d1a0c984b0ddb75dadca932ab9bef641343353b1204c4d473c9
      String unSigned =
          'cHNidP8BAF4CAAAAAQIGvU4cSUfRSFf9+D00pbUr4jANqffVnFJnWFDplO+UAAAAAAD/////AaNGXAUAAAAAIgAgtM9+myvnkbtyoKf5uDyMOk9RZqLUESQYGrOeKgBpGmwAAAAAAAEA/WABAgAAAAABAipt88abgqCNXUW4ZCfb0jttwHv6ExBSttavhNo+/RNOAAAAAAD/////yXPUxAQSOzVDE2Tvm6syqdzaddsNS5gMGg04bnDmLecAAAAAAP////8BfUhcBQAAAAAiACC0z36bK+eRu3Kgp/m4PIw6T1FmotQRJBgas54qAGkabAJHMEQCIEbhupbowY5vM8kz3gjzmIx/g7FIoSx65qh7u0pyDauiAiBEtSkVBhSNImG6Wdm93FOhXS63DvE43wluLp63SHOE/wEhA7ia3e3QkXCdcQAZNgE75+wYAKBNVodVmMgGg5qaaL4wAkgwRQIhAIz7qZrTdRbN1dUcXigXfglRj80Bk1aTRhMhPtuRPT5mAiBugZ1JAx3Df7ro9lTQgpGWZuAf9o11MTzaeaLUHewvIwEhA7ia3e3QkXCdcQAZNgE75+wYAKBNVodVmMgGg5qaaL4wAAAAAAEBK31IXAUAAAAAIgAgtM9+myvnkbtyoKf5uDyMOk9RZqLUESQYGrOeKgBpGmwiBgLmOUGaXnlqD7auwsWgpddEFupAXCftLO7UgSG3rt76Vhyu9bKTMAAAgAEAAIAAAACAAgAAgAAAAAAAAAAAIgYDLojvMPUxbPDvdTiUKH8BVwJQrbti3lAgNeDOfHqAL9ocutQbMzAAAIABAACAAAAAgAIAAIAAAAAAAAAAACIGA9RkF6pBzha1rQ3ccUT0s6zxLLStCyDHXcF0EDlPl5UEHGKpNsMwAACAAQAAgAAAAIACAACAAAAAAAAAAAABBWlSIQLmOUGaXnlqD7auwsWgpddEFupAXCftLO7UgSG3rt76ViEDLojvMPUxbPDvdTiUKH8BVwJQrbti3lAgNeDOfHqAL9ohA9RkF6pBzha1rQ3ccUT0s6zxLLStCyDHXcF0EDlPl5UEU64AAQMEo0ZcBQEEIyIAILTPfpsr55G7cqCn+bg8jDpPUWai1BEkGBqznioAaRpsIgIC5jlBml55ag+2rsLFoKXXRBbqQFwn7Szu1IEht67e+lYcrvWykzAAAIABAACAAAAAgAIAAIAAAAAAAAAAACICAy6I7zD1MWzw73U4lCh/AVcCUK27Yt5QIDXgznx6gC/aHLrUGzMwAACAAQAAgAAAAIACAACAAAAAAAAAAAAiAgPUZBeqQc4Wta0N3HFE9LOs8Sy0rQsgx13BdBA5T5eVBBxiqTbDMAAAgAEAAIAAAACAAgAAgAAAAAAAAAAAAAA=';
      String halfSigned =
          'cHNidP8BAF4CAAAAAQIGvU4cSUfRSFf9+D00pbUr4jANqffVnFJnWFDplO+UAAAAAAD/////AaNGXAUAAAAAIgAgtM9+myvnkbtyoKf5uDyMOk9RZqLUESQYGrOeKgBpGmwAAAAAAAEA/WABAgAAAAABAipt88abgqCNXUW4ZCfb0jttwHv6ExBSttavhNo+/RNOAAAAAAD/////yXPUxAQSOzVDE2Tvm6syqdzaddsNS5gMGg04bnDmLecAAAAAAP////8BfUhcBQAAAAAiACC0z36bK+eRu3Kgp/m4PIw6T1FmotQRJBgas54qAGkabAJHMEQCIEbhupbowY5vM8kz3gjzmIx/g7FIoSx65qh7u0pyDauiAiBEtSkVBhSNImG6Wdm93FOhXS63DvE43wluLp63SHOE/wEhA7ia3e3QkXCdcQAZNgE75+wYAKBNVodVmMgGg5qaaL4wAkgwRQIhAIz7qZrTdRbN1dUcXigXfglRj80Bk1aTRhMhPtuRPT5mAiBugZ1JAx3Df7ro9lTQgpGWZuAf9o11MTzaeaLUHewvIwEhA7ia3e3QkXCdcQAZNgE75+wYAKBNVodVmMgGg5qaaL4wAAAAAAEBK31IXAUAAAAAIgAgtM9+myvnkbtyoKf5uDyMOk9RZqLUESQYGrOeKgBpGmwiBgLmOUGaXnlqD7auwsWgpddEFupAXCftLO7UgSG3rt76Vhyu9bKTMAAAgAEAAIAAAACAAgAAgAAAAAAAAAAAIgYDLojvMPUxbPDvdTiUKH8BVwJQrbti3lAgNeDOfHqAL9ocutQbMzAAAIABAACAAAAAgAIAAIAAAAAAAAAAACIGA9RkF6pBzha1rQ3ccUT0s6zxLLStCyDHXcF0EDlPl5UEHGKpNsMwAACAAQAAgAAAAIACAACAAAAAAAAAAAABBWlSIQLmOUGaXnlqD7auwsWgpddEFupAXCftLO7UgSG3rt76ViEDLojvMPUxbPDvdTiUKH8BVwJQrbti3lAgNeDOfHqAL9ohA9RkF6pBzha1rQ3ccUT0s6zxLLStCyDHXcF0EDlPl5UEU64iAgLmOUGaXnlqD7auwsWgpddEFupAXCftLO7UgSG3rt76VkcwRAIgXhHcYO44UtMMAQNsarlpJAGiGHy2Xms7l0Zwt4ndAn0CIFtRLUxVj2sdJfOXZB2BIb11D2wkqd4GmG0wrgxP/wu/AQABAwSjRlwFAQQjIgAgtM9+myvnkbtyoKf5uDyMOk9RZqLUESQYGrOeKgBpGmwiAgLmOUGaXnlqD7auwsWgpddEFupAXCftLO7UgSG3rt76Vhyu9bKTMAAAgAEAAIAAAACAAgAAgAAAAAAAAAAAIgIDLojvMPUxbPDvdTiUKH8BVwJQrbti3lAgNeDOfHqAL9ocutQbMzAAAIABAACAAAAAgAIAAIAAAAAAAAAAACICA9RkF6pBzha1rQ3ccUT0s6zxLLStCyDHXcF0EDlPl5UEHGKpNsMwAACAAQAAgAAAAIACAACAAAAAAAAAAAAAAA==';
      String fullSigned =
          'cHNidP8BAF4CAAAAAQIGvU4cSUfRSFf9+D00pbUr4jANqffVnFJnWFDplO+UAAAAAAD/////AaNGXAUAAAAAIgAgtM9+myvnkbtyoKf5uDyMOk9RZqLUESQYGrOeKgBpGmwAAAAAAAEA/WABAgAAAAABAipt88abgqCNXUW4ZCfb0jttwHv6ExBSttavhNo+/RNOAAAAAAD/////yXPUxAQSOzVDE2Tvm6syqdzaddsNS5gMGg04bnDmLecAAAAAAP////8BfUhcBQAAAAAiACC0z36bK+eRu3Kgp/m4PIw6T1FmotQRJBgas54qAGkabAJHMEQCIEbhupbowY5vM8kz3gjzmIx/g7FIoSx65qh7u0pyDauiAiBEtSkVBhSNImG6Wdm93FOhXS63DvE43wluLp63SHOE/wEhA7ia3e3QkXCdcQAZNgE75+wYAKBNVodVmMgGg5qaaL4wAkgwRQIhAIz7qZrTdRbN1dUcXigXfglRj80Bk1aTRhMhPtuRPT5mAiBugZ1JAx3Df7ro9lTQgpGWZuAf9o11MTzaeaLUHewvIwEhA7ia3e3QkXCdcQAZNgE75+wYAKBNVodVmMgGg5qaaL4wAAAAAAEBK31IXAUAAAAAIgAgtM9+myvnkbtyoKf5uDyMOk9RZqLUESQYGrOeKgBpGmwiBgLmOUGaXnlqD7auwsWgpddEFupAXCftLO7UgSG3rt76Vhyu9bKTMAAAgAEAAIAAAACAAgAAgAAAAAAAAAAAIgYDLojvMPUxbPDvdTiUKH8BVwJQrbti3lAgNeDOfHqAL9ocutQbMzAAAIABAACAAAAAgAIAAIAAAAAAAAAAACIGA9RkF6pBzha1rQ3ccUT0s6zxLLStCyDHXcF0EDlPl5UEHGKpNsMwAACAAQAAgAAAAIACAACAAAAAAAAAAAABBWlSIQLmOUGaXnlqD7auwsWgpddEFupAXCftLO7UgSG3rt76ViEDLojvMPUxbPDvdTiUKH8BVwJQrbti3lAgNeDOfHqAL9ohA9RkF6pBzha1rQ3ccUT0s6zxLLStCyDHXcF0EDlPl5UEU64iAgLmOUGaXnlqD7auwsWgpddEFupAXCftLO7UgSG3rt76VkcwRAIgXhHcYO44UtMMAQNsarlpJAGiGHy2Xms7l0Zwt4ndAn0CIFtRLUxVj2sdJfOXZB2BIb11D2wkqd4GmG0wrgxP/wu/ASICAy6I7zD1MWzw73U4lCh/AVcCUK27Yt5QIDXgznx6gC/aRzBEAiB66Gd9frUUHoTuvW9auqNeljqdJb3J1PHFBydQJDHM+wIgMsaO9Bmj39dGWajOVc9iOaX7JF0uO8RdjkTU5vmxlhoBAAEDBKNGXAUBBCMiACC0z36bK+eRu3Kgp/m4PIw6T1FmotQRJBgas54qAGkabCICAuY5QZpeeWoPtq7CxaCl10QW6kBcJ+0s7tSBIbeu3vpWHK71spMwAACAAQAAgAAAAIACAACAAAAAAAAAAAAiAgMuiO8w9TFs8O91OJQofwFXAlCtu2LeUCA14M58eoAv2hy61BszMAAAgAEAAIAAAACAAgAAgAAAAAAAAAAAIgID1GQXqkHOFrWtDdxxRPSzrPEstK0LIMddwXQQOU+XlQQcYqk2wzAAAIABAACAAAAAgAIAAIAAAAAAAAAAAAAA';
      int expectedFee = 474;

      PSBT unSignedPSBT = PSBT.parse(unSigned);
      PSBT halfSignedPSBT = PSBT.parse(halfSigned);
      PSBT fullSignedPSBT = PSBT.parse(fullSigned);

      expect(
          unSignedPSBT.estimateFee(3, AddressType.p2wsh,
              requiredSignature: 2, totalSigner: 3),
          isWithinRange(expectedFee - 1, expectedFee + 1));
      expect(
          halfSignedPSBT.estimateFee(3, AddressType.p2wsh,
              requiredSignature: 2, totalSigner: 3),
          isWithinRange(expectedFee - 1, expectedFee + 1));
      expect(
          fullSignedPSBT.estimateFee(3, AddressType.p2wsh,
              requiredSignature: 2, totalSigner: 3),
          isWithinRange(expectedFee - 1, expectedFee + 1));
      expect(
          fullSignedPSBT.fee, isWithinRange(expectedFee - 1, expectedFee + 1));

      Transaction tx = fullSignedPSBT.getSignedTransaction(wallet.addressType);

      expect(
          tx.estimateFee(3, AddressType.p2wsh,
              requiredSignature: 2, totalSinger: 3),
          isWithinRange(expectedFee - 1, expectedFee + 1));
    });
  });
}
