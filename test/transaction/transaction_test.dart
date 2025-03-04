@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  group('Transaction', () {
    late Transaction legacyTransaction;
    late Transaction segwitTransaction;
    setUpAll(() {
      NetworkType.setNetworkType(NetworkType.regtest);
      String segwitTransactionText =
          '02000000000101a463a7a78daffa1bdb1248121adb14b94f70a1fabffc81637f4049c3d65cc69f00000000000000008002e803000000000000160014b247a00acc1cc2c0b4be0d3c38d866f9c08d244a051f000000000000160014d32c7c4dbb9457cff124c786bac87a9a706c5b3a02483045022100c2ce833d29b2bc4048e54fb5a9cb5131f31fe1254d4510339f3bfa2b6c3fe8120220576e45c680b2ab2fa184cf2b6caf7a165b1d5fc61cc165073017104011bfdc42012103324172078ccc5a19cf6db18b0c4bbd135b9d86131d6666bbd494c9474b3eb52600000000';
      String legacyTransactionText =
          '0100000001d06050454abde3bdd947312b9f54439acb097608a47b0b36a23d76820a3a4044000000006a4730440220360e6c5348a85270a3b14b84780ad56cd189bd12848b125c488a678f5e0d95be022011e51cfd849e5d005fc5352885a954c756f6073de633545f6045c4ad96ac9be0012102742148dd2f73733ce36202798298e8294b42b5aabf1ba87a9bb9b0167abfb8dfffffffff01277c5d000000000016001424b3e9491f3eadd9862389d98480acf89bdab07800000000';

      legacyTransaction = Transaction.parse(legacyTransactionText);
      segwitTransaction = Transaction.parse(segwitTransactionText);
    });
    group('get version', () {
      test('Get version of transaction', () {
        expect(legacyTransaction.version, '01000000');
        expect(segwitTransaction.version, '02000000');
      });
    });
    group('get inputs', () {
      test('Get transaction input list', () {
        expect(legacyTransaction.inputs.length, 1);
        expect(segwitTransaction.inputs.length, 1);
      });
    });
    group('get outputs', () {
      test('Get transaction output list', () {
        expect(legacyTransaction.outputs.length, 1);
        expect(segwitTransaction.outputs.length, 2);
      });
    });
    group('get transactionHash', () {
      test('Get transaction hash', () {
        expect(legacyTransaction.transactionHash,
            '5e2a36182c1566495489bb86ce85ef386095a709bc53c7363ec18c99467aa63c');
        expect(segwitTransaction.transactionHash,
            'efb4cadbc8fa6ab7970b461bbc99e506403397bddc3280cbf847c1684b61248b');
      });
    });
    group('get length', () {
      test('Get length of transaction', () {
        expect(legacyTransaction.length, 188);
        expect(segwitTransaction.length, 115);
      });
    });
    group('get utxoList', () {
      test('Get utxo list if exist', () {
        SingleSignatureVault vault = MockFactory.createP2wpkhVault();
        List<Utxo> utxoList = MockFactory.createUtxoList(count: 2);
        Transaction tx = Transaction.fromUtxoList(
            utxoList,
            {'bcrt1qk4z5ysfc2k72pz2ws4dhskxdq772s7uq6cdqkv': 100000},
            'bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg',
            1,
            vault);
        expect(tx.utxoList.length, 2);
      });
    });
    group('get totalSendingAmount', () {
      test('Get total sending amount', () {
        SingleSignatureVault vault = MockFactory.createP2wpkhVault();
        List<Utxo> utxos = MockFactory.createUtxoList(count: 5);
        Map<String, int> paymentMap = {
          'bcrt1qzf8qs6qgyq9kgu225jatvvx0nvvm3u3ka5gf7w': 1000,
          'bcrt1qwr2aleje6vh48xzh9djeap9qcnc7atf57l302c': 2000
        };
        String changeAddress = 'bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg';
        Transaction tx = Transaction.forBatchPayment(
            utxos, paymentMap, changeAddress, 1, vault);

        expect(tx.totalSendingAmount, 3000);
      });
    });
    group('Transaction.withDefault', () {
      test('', () {});
    });

    group('Transaction.withDefault', () {
      test('Generate default transaction', () {
        TransactionInput input = TransactionInput.parse(
            'a463a7a78daffa1bdb1248121adb14b94f70a1fabffc81637f4049c3d65cc69f000000000000000080');
        TransactionOutput output1 = TransactionOutput.parse(
            'e803000000000000160014b247a00acc1cc2c0b4be0d3c38d866f9c08d244a');
        TransactionOutput output2 = TransactionOutput.parse(
            '051f000000000000160014d32c7c4dbb9457cff124c786bac87a9a706c5b3a');
        Transaction tx = Transaction.withDefault(
            [input], [output1, output2], AddressType.p2wpkh);
        expect(tx, isA<Transaction>());
      });
    });
    group('Transaction.fromUtxoList', () {
      List<Utxo> utxos = MockFactory.createUtxoList(count: 5);
      String receiveAddress = 'bcrt1q8e5ghfg8gpe4dlfv7qqck2c2jc47lnllul3puh';
      String changeAddress = 'bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg';
      test(
          'Generate transaction from utxo list when change amount is under dust',
          () {
        SingleSignatureVault vault = MockFactory.createP2wpkhVault();

        Transaction tx = Transaction.fromUtxoList(utxos.sublist(0, 1),
            {receiveAddress: 99800}, changeAddress, 1, vault);
        int inputAmount = 0;
        int outputAmount = 0;
        for (Utxo u in tx.utxoList) {
          inputAmount += u.amount;
        }
        for (TransactionOutput output in tx.outputs) {
          outputAmount += output.amount;
        }
        expect(
            inputAmount >= outputAmount + tx.estimateFee(1, vault.addressType),
            true);
        expect(tx.outputs.length, 1);
      });
      test('Generate transactin with utxo list', () {
        SingleSignatureVault vault = MockFactory.createP2wpkhVault();
        List<Utxo> utxos = MockFactory.createUtxoList(count: 5);
        Transaction tx = Transaction.fromUtxoList(
            utxos, {receiveAddress: 4200}, changeAddress, 1, vault);
        expect(tx.outputs.length, 2);
      });
    });

    group('Transaction.forPayment', () {
      test('Generate transaction for payment', () {
        SingleSignatureVault vault = MockFactory.createP2wpkhVault();
        List<Utxo> utxos = MockFactory.createUtxoList(count: 5);
        String receiveAddress = 'bcrt1q8e5ghfg8gpe4dlfv7qqck2c2jc47lnllul3puh';
        String changeAddress = 'bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg';
        Transaction tx = Transaction.forPayment(
            utxos, receiveAddress, changeAddress, 3500, 1, vault);
        expect(tx.outputs[0].getAddress(), receiveAddress);
        expect(tx.outputs[1].getAddress(), changeAddress);
        expect(tx.outputs[0].amount, 3500);
      });
    });
    group('Transaction.forSweep', () {
      test('Generate transaction for sweep', () {
        SingleSignatureVault vault = MockFactory.createP2wpkhVault();
        List<Utxo> utxos = MockFactory.createUtxoList(count: 5);
        String receiveAddress = 'bcrt1q8e5ghfg8gpe4dlfv7qqck2c2jc47lnllul3puh';
        Transaction tx = Transaction.forSweep(utxos, receiveAddress, 1, vault);
        int utxoTotalAmount = 0;
        for (Utxo utxo in utxos) {
          utxoTotalAmount += utxo.amount;
        }
        expect(tx.outputs[0].amount < utxoTotalAmount, true);
        expect(tx.outputs.length, 1);
      });
    });
    group('Transaction.forBatchPayment', () {
      test('Generate transaction for batch', () {
        SingleSignatureVault vault = MockFactory.createP2wpkhVault();
        List<Utxo> utxos = MockFactory.createUtxoList(count: 5);
        Map<String, int> paymentMap = {
          'bcrt1qzf8qs6qgyq9kgu225jatvvx0nvvm3u3ka5gf7w': 1000,
          'bcrt1qwr2aleje6vh48xzh9djeap9qcnc7atf57l302c': 2000
        };
        String changeAddress = 'bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg';
        Transaction tx = Transaction.forBatchPayment(
            utxos, paymentMap, changeAddress, 1, vault);

        expect(tx.outputs.length == 3, isTrue);
        expect(tx.serialize().hashCode, 180007001);
      });
    });
    group('Transaction.parse', () {
      test('Generate transaction from parsing', () {
        String segwitTransactionText =
            '0100000000010126a348fa555f96162bc9e178d54dd8ebecf7f08ef20cc8415f3b4bd6756ada490300000000ffffffff035b5a2300000000001600144e778a823f6b0cd146fb9e63e33a80786c61ebc7ee5f03000000000017a914daffddf6f584eacfa1adbd88a98fdfc1e6f3510b87b4600f0000000000220020701a8d401c84fb13e6baf169d59684e17abd9fa216c8cc5b9fc63d622ff8c58d04004730440220311e2611916105cdc8b3be34ab2be50c97bebcaad598accc1c20b8244bdf3d77022072777a3754a231b57e404b94dbf7ee8d9cf20b29f35c9b310468a84aa792c1bd014730440220540695e2faab7ea0e7a54e744b2bf14234791eff4618ff74ebed481d85d0d5be02202f08aaef8b6e13dfba904d5af60811630b7dde051bec534af8008c1c6d1ff732016952210375e00eb72e29da82b89367947f29ef34afb75e8654f6ea368e0acdfd92976b7c2103a1b26313f430c4b15bb1fdce663207659d8cac749a0e53d70eff01874496feff2103c96d495bfdd5ba4145e3e046fee45e84a8a48ad05bd8dbb395c011a32cf9f88053ae00000000';
        String legacyTransactionText =
            '0200000004076b731f18a90c9ecfddec457decee3eaeb1b8919d8a993c53e339c2fd9e2b3e000000006b483045022100b4931427c733c2d966e2047226469540b8463d3e601b8f376fa4664ea2105920022043583f021048c649fbe52e83b1be9d4bfc87f64f75b07234f89327a794fd5ffc0121028fa220c9e1ea20d9564d96c8b6732691481883053bb69b87d4e979d16a285f54feffffff28d4197e9bfd01ca7bebb531c78ead18dff10c15b8f69b83eb1d2bd5817434cc010000006a47304402207317915f68dd601b78ff54ae5020ba4f6bdb14fab3071db79810678e8a48154f02202241f2c98a88965245b2623de611bc872f66f83e787de947772442071919843e0121034564c0bb191c40947afaead343e8a23ce4709a55d36a79bc44cf9909a15be5abfeffffff4ecab342f8478707e05d5eda43f9738c0bed2f31986722479ee8bb9b8c83866e000000006a473044022025af63029d9fa3f6b5b2a4ee7ee3a4563d70a721b9c606a461be97f648fd616202206483cd4078c2f6fc261ea0ec08581c8c7889e4cbf13714ad5a35b7e9010d14ab0121038473783342f751e23f672097116dd7c21d31b90e1b43aa9dcae31d0a0cc0dea4feffffff876c02d5fac718b2532e05a7cea386c9dc32796f6d569985bd1e6432bca4625d2c0000006a473044022041ff4f0d07abcf787ae5eca10827309b93aa0a6dda18d4728ecdf7afd30c674a02204fa0f18d448bfe37b83cefe238762e9b7d9bd557b72e4ba9a4afcccc8538bbfb012103839e5fba93a076683653ec02fb760046ecf161a9997726e0cdbca17293245ebdfeffffff0243420f00000000001976a914387e98494a92c2cf642b38ecbc7bbdfdb2900da588ac63351000000000001976a91462ef8a1fd034ac03705ad25899c6e1c4374e32de88ac9e730d00';
        expect(Transaction.parse(segwitTransactionText), isA<Transaction>());
        expect(Transaction.parse(legacyTransactionText), isA<Transaction>());
      });
    });
    group('Transaction.parseUnsignedTransaction', () {
      test('Generate unsigned transaction from parsing', () {
        String transactionText =
            '02000000000105f350552c40f031b89f88b71f5b358f6449a489296775f96d9a0110f9562d3a390000000000ffffffff64707f50c099875d92cf4a8aec9a6883501bd692251226085bccf9cd892289760000000000ffffffff5f0cd93abafa0cbfcc78053c7a2146349db00ebb9b6584cc965741a9ff2c075c0000000000ffffffff94f2ddc4e19a413dfce0220777c044bc35beb8e3e50418560aab2285cdc1454b0000000000fffffffffc520bd6a2585b695369f809dd856e800f953422f3f02ab0800eda352a2f33bc0000000000ffffffff01a29f0700000000001600143e688ba507407356fd2cf0018b2b0a962befcfff000000000000000000';
        expect(Transaction.parse(transactionText), isA<Transaction>());
      });
    });
    group('serialize', () {
      test('Serialize segwit transaction', () {
        String segwitTransactionText =
            '0100000000010126a348fa555f96162bc9e178d54dd8ebecf7f08ef20cc8415f3b4bd6756ada490300000000ffffffff035b5a2300000000001600144e778a823f6b0cd146fb9e63e33a80786c61ebc7ee5f03000000000017a914daffddf6f584eacfa1adbd88a98fdfc1e6f3510b87b4600f0000000000220020701a8d401c84fb13e6baf169d59684e17abd9fa216c8cc5b9fc63d622ff8c58d04004730440220311e2611916105cdc8b3be34ab2be50c97bebcaad598accc1c20b8244bdf3d77022072777a3754a231b57e404b94dbf7ee8d9cf20b29f35c9b310468a84aa792c1bd014730440220540695e2faab7ea0e7a54e744b2bf14234791eff4618ff74ebed481d85d0d5be02202f08aaef8b6e13dfba904d5af60811630b7dde051bec534af8008c1c6d1ff732016952210375e00eb72e29da82b89367947f29ef34afb75e8654f6ea368e0acdfd92976b7c2103a1b26313f430c4b15bb1fdce663207659d8cac749a0e53d70eff01874496feff2103c96d495bfdd5ba4145e3e046fee45e84a8a48ad05bd8dbb395c011a32cf9f88053ae00000000';
        Transaction segwitTransaction =
            Transaction.parse(segwitTransactionText);
        expect(segwitTransaction.serialize(), segwitTransactionText);
      });

      test('Serialize legacy transaction', () {
        String legacyTransactionText =
            '0200000004076b731f18a90c9ecfddec457decee3eaeb1b8919d8a993c53e339c2fd9e2b3e000000006b483045022100b4931427c733c2d966e2047226469540b8463d3e601b8f376fa4664ea2105920022043583f021048c649fbe52e83b1be9d4bfc87f64f75b07234f89327a794fd5ffc0121028fa220c9e1ea20d9564d96c8b6732691481883053bb69b87d4e979d16a285f54feffffff28d4197e9bfd01ca7bebb531c78ead18dff10c15b8f69b83eb1d2bd5817434cc010000006a47304402207317915f68dd601b78ff54ae5020ba4f6bdb14fab3071db79810678e8a48154f02202241f2c98a88965245b2623de611bc872f66f83e787de947772442071919843e0121034564c0bb191c40947afaead343e8a23ce4709a55d36a79bc44cf9909a15be5abfeffffff4ecab342f8478707e05d5eda43f9738c0bed2f31986722479ee8bb9b8c83866e000000006a473044022025af63029d9fa3f6b5b2a4ee7ee3a4563d70a721b9c606a461be97f648fd616202206483cd4078c2f6fc261ea0ec08581c8c7889e4cbf13714ad5a35b7e9010d14ab0121038473783342f751e23f672097116dd7c21d31b90e1b43aa9dcae31d0a0cc0dea4feffffff876c02d5fac718b2532e05a7cea386c9dc32796f6d569985bd1e6432bca4625d2c0000006a473044022041ff4f0d07abcf787ae5eca10827309b93aa0a6dda18d4728ecdf7afd30c674a02204fa0f18d448bfe37b83cefe238762e9b7d9bd557b72e4ba9a4afcccc8538bbfb012103839e5fba93a076683653ec02fb760046ecf161a9997726e0cdbca17293245ebdfeffffff0243420f00000000001976a914387e98494a92c2cf642b38ecbc7bbdfdb2900da588ac63351000000000001976a91462ef8a1fd034ac03705ad25899c6e1c4374e32de88ac9e730d00';
        Transaction tx = Transaction.parse(legacyTransactionText);
        expect(tx.serialize(), legacyTransactionText);
      });
    });
    group('getSigHash', () {
      test('Get segwit sighash', () {
        Transaction tx = Transaction.parse(
            '0100000002fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f0000000000eeffffffef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a0100000000ffffffff02202cb206000000001976a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac9093510d000000001976a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac11000000',
            isEmptySignature: true);
        TransactionOutput utxo2 = TransactionOutput(
            Converter.intToLittleEndianBytes(600000000, 8),
            ScriptPublicKey.parse(
                '1600141d0f172a0ecb48aee1be1f2687d2963ae33f71a1'));

        String sigHash2 = tx.getSigHash(1, utxo2, AddressType.p2wpkh);
        expect(sigHash2,
            'c37af31116d1b27caf68aae9e3ac82f1477929014d5b917657d0eb49478cb670');
      });
      test('Get legacy sighash', () {
        Transaction transaction = Transaction.parse(
            '010000000151b8b4228ece5c5895e57a46d462381b1171c05b0ae4e804213c0f89ce6a2eee010000006b4830450221008007f1f3b5d2446a5ab5af2cf462c60a4b5c8b333921760516a2f1c34ceb50490220364d8ac8d7e5215b311bf049748714b0f27837dbfe4aae0098fd74d817ed5f32012102671f1ae5ef3966dc547de554cccf34a0aaf1f245be325ca00dc54934f10736f30000008002d0c8480000000000160014a8ae93d3a541b120756eadd49b8b52eba2796e99ad45f900000000001976a91456c0bc2f50bc150d4ea122e66db7c48b01b9722988ac00000000',
            isEmptySignature: true);
        TransactionOutput utxo1 = TransactionOutput(
            Converter.intToLittleEndianBytes(21146336, 8),
            ScriptPublicKey.parse(
                '1976a91456c0bc2f50bc150d4ea122e66db7c48b01b9722988ac'));

        String sigHash = transaction.getSigHash(0, utxo1, AddressType.p2pkh);
        expect(sigHash,
            'b895e8018fe25df450f604c6cd93db1bbf4b1a4eefc3a67ebd2de68a0b908236');
      });
    });
    group('getTaprootSigHash', () {
      test('Get taproot sighash', () {
        //TODO: Implement test
      });
    });

    group('validateSignature', () {
      test('Validate signature of transaction', () {
        String transactionText =
            '020000000001016520eede29c5e034036a461980149268e263fed8a5b8e527ead8862123e3906b01000000000100000001f82a00000000000016001473f7aa4db6847eab27c59214f6ed7254627e7de002483045022100f369a3e1bdfb62a3ff875fa60bc9834326dead789a24ffcb2faf5f48628240e8022014cc216309a8ded296597cfd2680528729c0a55e43826d8af7d160d45be3df860121033b0492bf5c0a0222a55cdea04cdc022b1751112381ae6e9970319b3d6b161db900000000';
        Transaction tx = Transaction.parse(transactionText);
        String prevTxText =
            '02000000000101b388ce3d349385311d8c6e90217e206a66d30acb191369145779c2700a4a3d850000000000fdffffff0223e7141200000000160014c9d118b800a191f330e805dde37906bd8f703a8f042d000000000000160014cb325c29ac1d9f9c56ab77c7f659f6a304a7bd020247304402206c32ce7dce76088fdb81c36bba110ae4add38ecebff7ae03c36308293a0df97902203f78de99e909195bf0a8149650aed533ebab61c98be4d6adb886463dd550e3ff012102c78711069178ff17d77be53a7acedbbacac4daca293e42c61f7303362108fd2265052b00';
        Transaction prevTx = Transaction.parse(prevTxText);
        TransactionOutput utxo = prevTx.outputs[1];
        expect(tx.validateSignature(0, utxo, AddressType.p2wpkh), true);
      });
      test('Validate signature of transaction (false)', () {
        String transactionText =
            '020000000001016520eede29c5e034036a461980149268e263fed8a5b8e527ead8862123e3906b01000000000100000001f82a00000000000016001473f7aa4db6847eab27c59214f6ed7254627e7de002483045022100f369a3e1bdfb62a3ff875fa60bc9834326dead789a24ffcb2faf5f48628240e8022014cc216309a8ded296597cfd2680528729c0a55e43826d8af7d160d45be3df860121033b0492bf5c0a0222a55cdea04cdc022b1751112381ae6e9970319b3d6b161db900000000';
        Transaction tx = Transaction.parse(transactionText);
        String prevTxText =
            '02000000000101670c2a20b939d70170af0fc3be6e4baecf9a003df9b25ac64d3b0d18b43dc12b0200000000fdffffff033f3fc0380000000022512051db6dd7e0ceb9a4b189078555bffbeebd589d6237813b9c74bc457997c21d60e803000000000000160014cb325c29ac1d9f9c56ab77c7f659f6a304a7bd02960f000000000000225120eabe98a28e805ba56a0bce762af410f3998ee10e4c919d964dc91cf096f5a9cf0140875bc3d6e6f00d6020c095f5cc20744a1bf6ebb7bd2dbee415b8346024c6db13b1389809468d2deb6ce221c27b5bdc58a38a4a91909b5f6ac3fea26abe184347570b2b00';
        Transaction prevTx = Transaction.parse(prevTxText);
        TransactionOutput utxo = prevTx.outputs[1];
        expect(tx.validateSignature(0, utxo, AddressType.p2wpkh), false);
      });
    });
    group('validateTaprootSignature', () {
      test('Validate taproot signature of transaction', () {
        //TODO: Implement test
      });
    });
    group('getVirtualByte', () {
      test('Get virtual byte', () {
        expect(legacyTransaction.getVirtualByte(), 188.0);
        expect(segwitTransaction.getVirtualByte(), 140.5);
      });
    });
    group('estimateVirtualByte', () {
      test('Get estimated virtyal byte', () {
        SingleSignatureVault vault = MockFactory.createP2wpkhVault();
        List<Utxo> utxos = MockFactory.createUtxoList(count: 5);
        String receiveAddress = 'bcrt1q8e5ghfg8gpe4dlfv7qqck2c2jc47lnllul3puh';
        String changeAddress = 'bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg';
        Transaction tx = Transaction.fromUtxoList(
            utxos, {receiveAddress: 4200}, changeAddress, 1, vault);
        expect(tx.estimateVirtualByte(AddressType.p2wpkh), 412.75);
      });
      test('Get estimated virtual byte in p2tr', () {
        SingleSignatureVault vault =
            MockFactory.createP2trKeyPathSpendingVault();
        List<Utxo> utxos = MockFactory.createUtxoList(count: 1);
        Transaction tx = Transaction.forSweep(
            utxos,
            'bc1p5fdr2ht0y4rjckn869skpml7pulm8wx6lu4c5eezwngx3c3uupzssx4myf',
            1,
            vault);
        expect(tx.estimateVirtualByte(AddressType.p2trKeyPathSpending), 111.25);
      });
    });
    group('estimateFee', () {
      test('Get estimated fee', () {
        TransactionInput input = TransactionInput.parse(
            'a463a7a78daffa1bdb1248121adb14b94f70a1fabffc81637f4049c3d65cc69f000000000000000080');
        TransactionOutput output1 = TransactionOutput.parse(
            'e803000000000000160014b247a00acc1cc2c0b4be0d3c38d866f9c08d244a');
        TransactionOutput output2 = TransactionOutput.parse(
            '051f000000000000160014d32c7c4dbb9457cff124c786bac87a9a706c5b3a');
        Transaction tx = Transaction.withDefault(
            [input], [output1, output2], AddressType.p2wpkh);
        expect(tx.estimateFee(1, AddressType.p2wpkh), 141);
      });
    });
    group('addInputWithUtxo', () {
      SingleSignatureVault vault = MockFactory.createP2wpkhVault();
      List<Utxo> utxos = MockFactory.createUtxoList(count: 5);
      String receiveAddress = 'bcrt1q8e5ghfg8gpe4dlfv7qqck2c2jc47lnllul3puh';
      String changeAddress = 'bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg';
      int feeRate = 2;
      test('Add input with utxo', () {
        Transaction tx = Transaction.forPayment(
            utxos, receiveAddress, changeAddress, 3200, feeRate, vault);
        int beforeInputLength = tx.inputs.length;

        tx.addInputWithUtxo(utxos[4], feeRate, vault);

        int afterInputLength = tx.inputs.length;

        int inputAmount = 0;
        for (Utxo u in tx.utxoList) {
          inputAmount += u.amount;
        }
        int outputAmount = 0;
        for (TransactionOutput output in tx.outputs) {
          outputAmount += output.amount;
        }

        expect(afterInputLength, beforeInputLength + 1);
        expect(
            inputAmount >=
                outputAmount + tx.estimateFee(feeRate, vault.addressType),
            true);
      });
      test('Add utxo in dust change case', () {
        int feeRate = 2;

        Transaction tx = Transaction.fromUtxoList(utxos.sublist(0, 3),
            {receiveAddress: 399300}, changeAddress, feeRate, vault);
        int beforeInputLength = tx.inputs.length;

        tx.addInputWithUtxo(utxos[4], feeRate, vault);

        int afterInputLength = tx.inputs.length;
        int inputAmount = 0;
        for (Utxo u in tx.utxoList) {
          inputAmount += u.amount;
        }

        int outputAmount = 0;
        for (TransactionOutput output in tx.outputs) {
          outputAmount += output.amount;
        }
        expect(afterInputLength, beforeInputLength + 1);
        expect(tx.outputs.length, 1);
        expect(
            inputAmount >=
                outputAmount + tx.estimateFee(feeRate, vault.addressType),
            true);
      });
    });
    group('removeInputWithUtxo', () {
      SingleSignatureVault vault = MockFactory.createP2wpkhVault();
      List<Utxo> utxos = MockFactory.createUtxoList(count: 5);
      String receiveAddress = 'bcrt1q8e5ghfg8gpe4dlfv7qqck2c2jc47lnllul3puh';
      String changeAddress = 'bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg';
      int feeRate = 2;
      test('Remove utxo in dust change case', () {
        Transaction tx = Transaction.fromUtxoList(utxos.sublist(0, 4),
            {receiveAddress: 299300}, changeAddress, feeRate, vault);
        int beforeInputLength = tx.inputs.length;

        tx.removeInputWithUtxo(utxos[3], feeRate, vault);
        int afterInputLength = tx.inputs.length;
        int inputAmount = 0;
        for (Utxo u in tx.utxoList) {
          inputAmount += u.amount;
        }
        int outputAmount = 0;
        for (TransactionOutput output in tx.outputs) {
          outputAmount += output.amount;
        }
        expect(afterInputLength, beforeInputLength - 1);
        expect(tx.outputs.length, 1);
        expect(
            inputAmount >=
                outputAmount + tx.estimateFee(feeRate, vault.addressType),
            true);
      });
    });
    group('updateFeeRate', () {
      SingleSignatureVault vault = MockFactory.createP2wpkhVault();
      List<Utxo> utxos = MockFactory.createUtxoList(count: 5);
      String receiveAddress = 'bcrt1q8e5ghfg8gpe4dlfv7qqck2c2jc47lnllul3puh';
      String changeAddress = 'bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg';
      test('Lower fee rate', () {
        int beforeFeeRate = 4;
        int afterFeeRate = 2;
        Transaction tx = Transaction.fromUtxoList(utxos.sublist(0, 4),
            {receiveAddress: 24000}, changeAddress, beforeFeeRate, vault);

        int beforeChange = tx.outputs[1].amount;

        tx.updateFeeRate(afterFeeRate, vault);
        int afterChange = tx.outputs[1].amount;
        expect(afterChange > beforeChange, true);
      });

      test('Higher fee rate', () {
        int beforeFeeRate = 2;
        int afterFeeRate = 4;
        Transaction tx = Transaction.fromUtxoList(utxos.sublist(0, 4),
            {receiveAddress: 240000}, changeAddress, beforeFeeRate, vault);
        int beforeChange = tx.outputs[1].amount;

        tx.updateFeeRate(afterFeeRate, vault);
        int afterChange = tx.outputs[1].amount;

        expect(afterChange < beforeChange, true);
      });
      test('Higher fee rate and dust threshold', () {
        int beforeFeeRate = 2;
        int afterFeeRate = 5;

        Transaction tx = Transaction.fromUtxoList(utxos.sublist(0, 4),
            {receiveAddress: 398200}, changeAddress, beforeFeeRate, vault);

        tx.updateFeeRate(afterFeeRate, vault);
        int inputAmount = 0;
        int outputAmount = 0;
        for (TransactionOutput output in tx.outputs) {
          outputAmount += output.amount;
        }
        for (Utxo u in tx.utxoList) {
          inputAmount += u.amount;
        }
        expect(tx.outputs.length, 1);
        expect(
            inputAmount >=
                outputAmount + tx.estimateFee(afterFeeRate, vault.addressType),
            true);
      });
      test('For sweep case', () {
        int beforeFeeRate = 2;
        int afterFeeRate = 5;

        Transaction tx = Transaction.forSweep(
            utxos.sublist(0, 4), receiveAddress, beforeFeeRate, vault);

        int beforeSendindAmount = tx.outputs[0].amount;
        tx.updateFeeRate(afterFeeRate, vault);

        int afterSendAmount = tx.outputs[0].amount;
        expect(tx.outputs.length, 1);
        expect(beforeSendindAmount >= afterSendAmount, true);
      });
    });
  });
}
