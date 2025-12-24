import argparse
import random
from typing import Iterable

from sqlalchemy import text

from app.db import engine


SERVICE_CATALOG = [
    {"base": "Массаж", "variants": ["спины", "шеи", "ног", "классический", "точечный", "лимфо"], "price": (900, 1800), "durations": [30, 45, 60]},
    {"base": "Сауна", "variants": ["финская", "кедровая", "инфра", "арома"], "price": (700, 1400), "durations": [30, 60, 90]},
    {"base": "СПА-уход", "variants": ["лицо", "тело", "антистресс"], "price": (1200, 2500), "durations": [40, 60, 90]},
    {"base": "Грязелечение", "variants": ["аппликации", "обертывание"], "price": (1000, 2000), "durations": [20, 30, 40]},
    {"base": "Ингаляции", "variants": ["травы", "минеральные", "солевые"], "price": (500, 900), "durations": [10, 15, 20]},
    {"base": "ЛФК", "variants": ["группа", "индивид"], "price": (600, 1200), "durations": [30, 45, 60]},
    {"base": "Физиотерапия", "variants": ["магнит", "ультразвук", "лазер"], "price": (700, 1600), "durations": [15, 20, 30]},
    {"base": "Косметология", "variants": ["уход", "маска", "пилинг"], "price": (900, 2000), "durations": [30, 45, 60]},
    {"base": "Соляная комната", "variants": ["сеанс", "дети", "релакс"], "price": (600, 1200), "durations": [30, 45]},
    {"base": "Бассейн", "variants": ["свободно", "аквааэробика"], "price": (400, 900), "durations": [45, 60]},
    {"base": "Гидромассаж", "variants": ["ванна", "душ"], "price": (800, 1500), "durations": [20, 30]},
    {"base": "Ароматерапия", "variants": ["сеанс", "релакс"], "price": (600, 1100), "durations": [20, 30, 40]},
    {"base": "Йога", "variants": ["группа", "утро"], "price": (500, 900), "durations": [45, 60]},
    {"base": "Пилатес", "variants": ["группа", "мягкий"], "price": (500, 900), "durations": [45, 60]},
    {"base": "Диет-консульт", "variants": ["первый", "повтор"], "price": (800, 1500), "durations": [30, 45]},
    {"base": "Фитобар", "variants": ["кислород", "травы"], "price": (200, 600), "durations": [10, 15]},
]

NAME_TAGS = ["VIP", "лайт", "про"]
MAX_NAME_LEN = 30


def build_name(base: str, variant: str | None, tag: str | None) -> str:
    parts = [base]
    if variant:
        parts.append(variant)
    name = " ".join(parts)
    if tag and len(name) + 1 + len(tag) <= MAX_NAME_LEN:
        name = f"{name} {tag}"
    if len(name) > MAX_NAME_LEN:
        name = base
        if tag and len(base) + 1 + len(tag) <= MAX_NAME_LEN:
            name = f"{base} {tag}"
    return name[:MAX_NAME_LEN]


def make_unique(name: str, seen: dict[str, int]) -> str:
    if name not in seen:
        seen[name] = 1
        return name
    seen[name] += 1
    suffix = f" {seen[name]}"
    if len(name) + len(suffix) <= MAX_NAME_LEN:
        return f"{name}{suffix}"
    return f"{name[: MAX_NAME_LEN - len(suffix)]}{suffix}"


def generate_services(count: int, rng: random.Random) -> Iterable[dict[str, object]]:
    seen: dict[str, int] = {}
    for _ in range(count):
        entry = rng.choice(SERVICE_CATALOG)
        variant = rng.choice(entry["variants"]) if entry["variants"] else None
        tag = rng.choice(NAME_TAGS) if rng.random() < 0.25 else None
        name = build_name(entry["base"], variant, tag)
        name = make_unique(name, seen)
        low, high = entry["price"]
        price = rng.randint(low, high)
        duration = rng.choice(entry["durations"])
        yield {"name": name, "price": price, "time": f"{duration} мин"}


def seed_services(count: int, clear: bool, seed: int) -> None:
    rng = random.Random(seed)
    rows = list(generate_services(count, rng))
    with engine.begin() as conn:
        if clear:
            conn.execute(text("DELETE FROM using_service"))
            conn.execute(text("DELETE FROM provision_of_services"))
            conn.execute(text("DELETE FROM service"))
            conn.execute(text("DBCC CHECKIDENT('service', RESEED, 0)"))
        conn.execute(
            text("INSERT INTO service (name, price, time) VALUES (:name, :price, :time)"),
            rows,
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed SQL Server data via SQLAlchemy.")
    parser.add_argument("--services", type=int, default=500, help="How many services to insert.")
    parser.add_argument("--clear", action="store_true", help="Clear service tables before insert.")
    parser.add_argument("--seed", type=int, default=42, help="RNG seed for repeatable data.")
    args = parser.parse_args()

    seed_services(args.services, args.clear, args.seed)


if __name__ == "__main__":
    main()
