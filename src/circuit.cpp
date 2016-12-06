#include "circuit.h"


Component::Component()
{
}

Component::Component(const std::string &_packageName, const Via &_pin0AbsPos)
  : packageName(_packageName), pin0AbsPos(_pin0AbsPos)
{
}

ConnectionPoint::ConnectionPoint(const std::string &_componentName, int _pinIdx)
  : componentName(_componentName), pinIdx(_pinIdx)
{
}

Connection::Connection(const ConnectionPoint &_start,
                       const ConnectionPoint &_end)
  : start(_start), end(_end)
{
}

Circuit::Circuit()
  : hasError(false)
{
}

ConnectionViaVec Circuit::genConnectionViaVec()
{
  ConnectionViaVec v;
  for (auto c : connectionVec) {
    auto startComponent = componentNameToInfoMap[c.start.componentName];
    auto endComponent = componentNameToInfoMap[c.end.componentName];

    auto
      startRelPin = packageToPosMap[startComponent.packageName][c.start.pinIdx];
    auto endRelPin = packageToPosMap[endComponent.packageName][c.end.pinIdx];

    Via startAbsPin = startRelPin + startComponent.pin0AbsPos;
    Via endAbsPin = endRelPin + endComponent.pin0AbsPos;

    v.push_back(ViaStartEnd(startAbsPin, endAbsPin));
  }
  return v;
}

PinViaVec Circuit::calcComponentPins(std::string componentName)
{
  PinViaVec v;
  const Component component = componentNameToInfoMap[componentName];
  for (auto c : packageToPosMap[component.packageName]) {
    c += component.pin0AbsPos;
    v.push_back(c);
  }
  return v;
}

ViaStartEnd Circuit::calcComponentFootprint(std::string componentName) const
{
  ViaStartEnd v(Via(INT_MAX, INT_MAX), Via(0, 0));
  auto component =
    (const_cast<Circuit *>(this))->componentNameToInfoMap[componentName];
  for (auto c : (const_cast<Circuit *>(this))->packageToPosMap[component
    .packageName]) {
    c += component.pin0AbsPos;
    if (c.x() < v.start.x()) {
      v.start.x() = c.x();
    }
    if (c.x() > v.end.x()) {
      v.end.x() = c.x();
    }
    if (c.y() < v.start.y()) {
      v.start.y() = c.y();
    }
    if (c.y() > v.end.y()) {
      v.end.y() = c.y();
    }
  }
  return v;
}
