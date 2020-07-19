namespace Nazg\EventDispatcher;

interface ListenerInterface {

  public function handle(
    Event $event,
    string $eventName,
    EventDispatcher $dispathcher
  ): void;
}
