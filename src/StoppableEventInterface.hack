namespace Nazg\EventDispatcher;

interface StoppableEventInterface {

  /**
   * Is propagation stopped?
   *
   * This will typically only be used by the Dispatcher to determine if the
   * previous listener halted propagation.
   */
  public function isPropagationStopped() : bool;
}
