import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/utils/converter.dart';

void main() async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  KeyStore key1 = KeyStore(
      AddressType.p2wsh,
      '51E6E98F',
      HDWallet.fromPublicKey(
          Converter.hexToBytes(
              '02cb084900e93b87a701eaaaa2c6d3e2f7c21d5ad82014c076e3450ce9e7a476bc'),
          Converter.hexToBytes(
              'ca4b263cc38a32c5a475c6d0babdf06dcd71f96a3cd26b92aaab355528f33b3c')),
      ExtendedPublicKey.parse(
          'Vpub5nXTZ2jYUcA2Goh9bWEnTr7SxKwPPkKW2XzBvjDuXtxyTpXx7H7TdL52Ppn91WyxPDnG3W8MS8ZVrKo3J2q4qn3cw48trXZSuNCqgQMUNMz'));

  KeyStore key2 = KeyStore(
      AddressType.p2wsh,
      'E41BFDEE',
      HDWallet.fromPublicKey(
          Converter.hexToBytes(
              '03076efe1d527dcfc48477282d64e479e635134a88c08e2701fff8d7a292852ef2'),
          Converter.hexToBytes(
              '4eecbfc5cc975ebbb837747491cfdca9ea4fa1bcbc483884c51dcbe777c82955')),
      ExtendedPublicKey.parse(
          'Vpub5mshynTDJgSr4LQRZTbqkLRRUBk65re7FRqkNWureEEB9hcoXLYSEhBhzPUAAioodMhoQAZD1L85M5jEJpb4vqtgxYYJWCpaN5HhiDCExBj'));
  KeyStore key3 = KeyStore(
      AddressType.p2wsh,
      'F6036596',
      HDWallet.fromPublicKey(
          Converter.hexToBytes(
              '033b90db194bab22739a8a5b994249bf26d94eec921e3da91e00507a28561ce880'),
          Converter.hexToBytes(
              '3b662507da15a723a61fb9fd8d38ee35ba7660b1d766395ebcb023d496483d0d')),
      ExtendedPublicKey.parse(
          'Vpub5nJ4GdJcGbM1acB9NUnwQWWrMrfZHNsAoXnnJWJbwKcnQ6UZCwteU3BNEDJbTTJ6D8jPL6fmhk6YMaCkfmQXJFsDGiasXPv88q6jsU4uRmt'));
  MultisignatureVault vault = MultisignatureVault.fromKeyStoreList(
      [key1, key2, key3], 2, AddressType.p2wsh);

  MultisignatureWallet wallet =
      MultisignatureWallet.fromDescriptor(vault.descriptor);

  for (Address address in wallet.addressBook.changeList) {
    print(address
        .address); //tb1qmr3arkjy4gys0nw7he3ppdsyg33r5mz4889ytwpgz654wwtlf8xsryqye5
  }
  PSBT psbt = PSBT.parse(
      'cHNidP8BAH0CAAAAASsb6CtepexkyiTz9o/tZw0FG5R//ppgmfaMKx4WZU+PAQAAAAD/////AkBLTAAAAAAAFgAUhHSd1dR1W23/DNxIAFAeEKH7b6kalakFAAAAACIAINjj0dpEqgkHzd6+YhC2BERiOmxVOcpFuCgWqVc5f0nNAAAAAAABAP2KAQIAAAAAAQInCWkgHAVbrs2GbUFdj9s7loKuV2V+6XalYFq2aj0RkAAAAAAA/f///9ecTjCnN5GCF2b+zqLh9SEqztITQxmKr+zelCZdD14sAQAAAAD9////Ahy6vgAAAAAAIlEg2jzSpsgaWc5cnN+hb7RJEgakJYEaN2DkuTlYAm2jNqEA4fUFAAAAACIAIKb+fKbiZIiQfWAKR5FuyWd+kBLOCazF1y+TZ8IGNvwXAkcwRAIgeLsnph1kLV48ffgttpYxr0Q2DbVdE3qzgpms2+Wc9xkCIE12fWVVXe7H5yNBhExFzJfvqtHukn5msD2dlJisw9pLASEDCcZZh/ipTWY1Rbtr9kWZl7c5xsXOVyoo08amNENGorsCRzBEAiBxLcHBWnlxDnwu0CHz/PTywzvst+qsbFAUcmwtB01uIAIgcNRNR5ocXgiFIj6GraK4T+z1bQpjGYKWCa1XSsaD+toBIQJ0i1Y0xVMd+mxl+YsGmNmB98C+JotMDA95U+V73q4on1qNAAABASsA4fUFAAAAACIAIKb+fKbiZIiQfWAKR5FuyWd+kBLOCazF1y+TZ8IGNvwXIgYDHH13WwtXcHdpC3z+NWI4JvInKiS1kVZ1JKA8qMpWOwgcUebpjzAAAIABAACAAAAAgAIAAIAAAAAAAAAAACIGAlly3oEJ0+PFxPQytNi5OgazXa5RP/s3k7HV7yYGQYS1HOQb/e4wAACAAQAAgAAAAIACAACAAAAAAAAAAAAiBgNe4yY6C+mlcgJ2ObedOs1m+uUZWMoqcTfUhljR/dFwQRz2A2WWMAAAgAEAAIAAAACAAgAAgAAAAAAAAAAAAQVpUiEDHH13WwtXcHdpC3z+NWI4JvInKiS1kVZ1JKA8qMpWOwghAlly3oEJ0+PFxPQytNi5OgazXa5RP/s3k7HV7yYGQYS1IQNe4yY6C+mlcgJ2ObedOs1m+uUZWMoqcTfUhljR/dFwQVOuAAEDBEBLTAABBBcWABSEdJ3V1HVbbf8M3EgAUB4QoftvqQABAwQalakFAQQjIgAg2OPR2kSqCQfN3r5iELYERGI6bFU5ykW4KBapVzl/Sc0iAgNVCqaM+2xFdyNz20CPsV/qgGkN/Hx01IRRRXQzLtfoBBxR5umPMAAAgAEAAIAAAACAAgAAgAEAAAAAAAAAIgICxC/y83+/RRo/QbdG0465Wg+HPDQUfmZVmSkPAiQhJ34c5Bv97jAAAIABAACAAAAAgAIAAIABAAAAAAAAACICArBkywYFTcUou9vng3JBbXbXs/Z2Jd1f5EiYtumYQWIqHPYDZZYwAACAAQAAgAAAAIACAACAAQAAAAAAAAAAAA==');
  for (PsbtOutput output in psbt.outputs) {
    print(output.getAddress());
    print(output.amount);
  }
  print("Sending Amount : " + psbt.sendingAmount.toString());
  Transfer transfer = Transfer.fromTransactions(
      wallet.addressBook, psbt.getSignedTransaction(AddressType.p2wsh));

  print(transfer.amount);
}
