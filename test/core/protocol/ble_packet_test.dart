import 'package:cyberskin_app/core/protocol/ble_packet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes and decodes a command packet with additive checksum', () {
    const packet = BlePacket(
      direction: BlePacketDirection.command,
      command: 0x57,
      payload: <int>[0x01, 0x10],
    );

    final bytes = packet.toBytes();
    expect(bytes, <int>[0xAA, 0x57, 0x01, 0x10, 0x68]);
    expect(BlePacket.fromBytes(bytes).payload, <int>[0x01, 0x10]);
  });

  test('rejects packets with an invalid checksum', () {
    expect(
      () => BlePacket.fromBytes(<int>[0xAA, 0x57, 0x01, 0x10, 0x69]),
      throwsFormatException,
    );
  });
}
