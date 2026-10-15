import unittest

from zowie_daemon import estimate_percent, estimate_rate, parse_battery


class EstimatePercentTest(unittest.TestCase):
    def test_bounds(self) -> None:
        self.assertEqual(estimate_percent(3000), 0)
        self.assertEqual(estimate_percent(4300), 100)

    def test_matches_mouse_readings(self) -> None:
        self.assertEqual(estimate_percent(4029), 81)
        self.assertEqual(estimate_percent(4093), 87)

    def test_interpolates_between_points(self) -> None:
        self.assertEqual(estimate_percent(3720), 18)


class ParseBatteryTest(unittest.TestCase):
    def test_linked(self) -> None:
        self.assertEqual(parse_battery(bytes.fromhex("d00f55ec") + bytes(60)), (4048, 85))

    def test_mouse_off(self) -> None:
        self.assertIsNone(parse_battery(bytes.fromhex("000000ec") + bytes(60)))


class EstimateRateTest(unittest.TestCase):
    def test_supported_rates(self) -> None:
        self.assertEqual(estimate_rate([0.008] * 10), 125)
        self.assertEqual(estimate_rate([0.002, 0.0021, 0.0019] * 4), 500)
        self.assertEqual(estimate_rate([0.001, 0.0009, 0.0011] * 4), 1000)

    def test_skipped_frames_at_500_are_not_250(self) -> None:
        self.assertIsNone(estimate_rate([0.004] * 10))

    def test_uneven_gaps_are_rejected(self) -> None:
        self.assertIsNone(estimate_rate([0.001, 0.002, 0.003, 0.001, 0.002] * 4))


if __name__ == "__main__":
    unittest.main()
