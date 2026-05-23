from pydantic import BaseModel


class ProfileUpdate(BaseModel):
    display_name: str | None = None
    timezone: str | None = None
    locale: str | None = None


class StyleProfileUpdate(BaseModel):
    style_vibes: list[str] | None = None
    color_palette_pref: list[str] | None = None
    occasions: list[str] | None = None
    climate: str | None = None
    goals: list[str] | None = None
    onboarding_completed: bool | None = None


class StyleProfileOut(BaseModel):
    id: str
    style_vibes: list[str]
    color_palette_pref: list[str]
    occasions: list[str]
    climate: str | None
    goals: list[str]
    onboarding_completed: bool
    model_config = {"from_attributes": True}
