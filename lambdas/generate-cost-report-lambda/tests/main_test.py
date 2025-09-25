from datetime import date

import pytest

from main import resolve_report_date


class StubClock:
    def __init__(self, stub_date):
        self.stub_date = stub_date

    def date_now(self):
        return self.stub_date


def test_resolve_report_date_returns_specified_month_if_overridden():
    report_date = resolve_report_date('2023', '02')
    assert report_date == {"month": 2, "year": 2023}


def test_resolve_report_date_throws_error_if_date_format_invalid():
    with pytest.raises(ValueError):
        resolve_report_date('2023', 'Feb')


def test_resolve_report_date_returns_last_month_if_not_overridden():
    april_clock = StubClock(date(2023, 4, 3))
    report_date = resolve_report_date(None, None, april_clock)
    assert report_date == {"month": 3, "year": 2023}


def test_resolve_report_date_returns_dec_of_last_year_if_current_month_is_jan():
    jan_clock = StubClock(date(2023, 1, 31))
    report_date = resolve_report_date(None, None, jan_clock)
    assert report_date == {"month": 12, "year": 2022}
