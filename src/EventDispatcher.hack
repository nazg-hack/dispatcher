namespace Nazg\EventDispatcher;

use namespace HH\Lib\{Dict, C};
use function array_key_exists;
use function array_filter;

class EventDispatcher {

  private dict<string, dict<int, vec<ListenerInterface>>> $listeners = dict[];
  private dict<string, dict<int, ListenerInterface>> $sorted = dict[];

  public function dispatch(Event $event, string $eventName): Event {
    $listeners = $this->getListeners($eventName);
    if ($listeners) {
      $this->callListeners($listeners, $eventName, $event);
    }
    return $event;
  }

  <<__Rx>>
  public function hasListeners(
    ?string $eventName = null
  ): bool {
    if ($eventName is nonnull) {
      return !array_key_exists($eventName, $this->listeners);
    }
    if(C\count($this->listeners)) {
      return true;
    }
    return false;
  }

  public function addListener(
    string $eventName,
    ListenerInterface $listener,
    int $priority = 0
  ): void {
    $this->listeners[$eventName][$priority][] = $listener;
  }

  protected function callListeners(
    dict<int, ListenerInterface> $listeners,
    string $eventName,
    Event $event
  ): void {
    foreach ($listeners as $listener) {
      if ($event->isPropagationStopped()) {
        break;
      }
      $listener->handle($event, $eventName, $this);
    }
  }

  private function sortListeners(
    string $eventName
  ): void {
    Dict\sort_by_key($this->listeners[$eventName]);
    $this->sorted[$eventName] = dict[];
    foreach ($this->listeners[$eventName] as $listeners) {
      foreach ($listeners as $k => $listener) {
        $this->sorted[$eventName][] = $listener;
      }
    }
  }

  public function getListeners(
    ?string $eventName = null
  ): dict<arraykey, ListenerInterface> {
    if ($eventName is nonnull) {
      if (!C\count($this->listeners[$eventName])) {
        return dict[];
      }
    
      if (!array_key_exists($eventName, $this->sorted)) {
        $this->sortListeners($eventName);
      }
      return $this->sorted[$eventName];
    }
    foreach ($this->listeners as $eventName => $eventListeners) {
      if (!array_key_exists($eventName, $this->sorted)) {
        $this->sortListeners($eventName);
      }
    }
    $sorted = array_filter($this->sorted);
    $d = dict[];
    foreach ($sorted as $key => $value) {
      $d[$key] = $value;
    }
    /* HH_FIXME[4110] */
    return $d;
  }
}
