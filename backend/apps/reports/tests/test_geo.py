import pytest

from apps.reports.geo import bbox_from_query, city_polygon, is_inside_city, point_from_lat_lon


def test_point_uses_longitude_as_x_and_latitude_as_y():
    point = point_from_lat_lon(21.1430, -88.1519)

    assert point.x == -88.1519
    assert point.y == 21.1430
    assert point.srid == 4326


def test_point_inside_city():
    point = point_from_lat_lon(21.1430, -88.1519)

    assert is_inside_city(point) is True


def test_point_outside_city():
    point = point_from_lat_lon(0, 0)

    assert is_inside_city(point) is False


def test_city_polygon_uses_settings_bbox():
    polygon = city_polygon()

    assert polygon.srid == 4326
    assert polygon.extent == (-88.19, 21.11, -88.11, 21.18)


@pytest.mark.parametrize("value", ["1,2,3", "a,b,c,d", "10,20,5,30", "5,30,10,20"])
def test_invalid_bbox_is_rejected(value):
    with pytest.raises(ValueError):
        bbox_from_query(value)


def test_valid_bbox_is_a_polygon():
    polygon = bbox_from_query("-88.17,21.12,-88.13,21.17")

    assert polygon.srid == 4326
    assert polygon.extent == (-88.17, 21.12, -88.13, 21.17)
