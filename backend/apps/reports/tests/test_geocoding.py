import pytest

from apps.reports.geo import point_from_lat_lon
from apps.reports.geocoding import reverse_geocode


@pytest.mark.django_db
def test_reverse_geocode_formats_a_street_address(settings, mocker):
    settings.GEOCODING_ENABLED = True
    response = mocker.Mock()
    response.raise_for_status.return_value = None
    response.json.return_value = {
        "address": {
            "road": "Calle 49",
            "house_number": "617",
            "suburb": "Centro",
            "city": "Tizimín",
            "state": "Yucatán",
        }
    }
    mocker.patch("apps.reports.geocoding.requests.get", return_value=response)

    address = reverse_geocode(point_from_lat_lon(21.1430, -88.1519))

    assert address == "Calle 49 617, Centro, Tizimín, Yucatán"


@pytest.mark.django_db
def test_reverse_geocode_returns_empty_when_disabled(settings):
    settings.GEOCODING_ENABLED = False

    assert reverse_geocode(point_from_lat_lon(21.1430, -88.1519)) == ""
