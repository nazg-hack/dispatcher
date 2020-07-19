namespace Nazg\EventDispatcher;

class Event implements StoppableEventInterface {

  private bool $propagationStopped = false;

  <<__Rx>>
  public function isPropagationStopped(): bool {
    return $this->propagationStopped;
  }

  public function stopPropagation(): void {
    $this->propagationStopped = true;
  }
}
