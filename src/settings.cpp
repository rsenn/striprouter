#include "settings.h"

Settings::Settings()
    : wire_cost(DEFAULT_WIRE_COST), strip_cost(DEFAULT_STRIP_COST), via_cost(DEFAULT_VIA_COST),
      cut_cost(DEFAULT_CUT_COST), pause(false) {}
