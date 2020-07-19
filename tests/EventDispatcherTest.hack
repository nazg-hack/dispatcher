use type Nazg\EventDispatcher\{Event, EventDispatcher, ListenerInterface};
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

final class EventDispatcherTest extends HackTest {

  public async function testShouldBeEmptyDict(): Awaitable<void> {
    $dispatcher = new EventDispatcher();
    expect($dispatcher->getListeners())->toBeSame(dict[]);
  }
}

class MockListener implements ListenerInterface {
  public function handle(
    Event $event,
    string $eventName,
    EventDispatcher $dispathcher
  ): void {

  }
}
