use type Nazg\Dispatcher\Dispatcher;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

final class DispatcherTest extends HackTest {

  private int $call = 0;

  public async function testShouldReturnInctID(): Awaitable<void> {
    $dispatcher = new Dispatcher();
    $id = $dispatcher->register(($v) ==> {
      $v;
    });
    expect($id)->toBeSame('ID_2');
    $id = $dispatcher->register(($v) ==> {
      $v;
    });
    expect($id)->toBeSame('ID_3');
  }

  public async function testShouldThrowInvariantException(): Awaitable<void> {
    $dispatcher = new Dispatcher();
    expect(() ==> $dispatcher->unregister('ID_1'))
      ->toThrow(InvariantException::class);
  }

  public async function testShouldExecuteCallbacks(): Awaitable<void> {
    $dispatcher = new Dispatcher();
    $id = $dispatcher->register(($_) ==> {
      $this->call = $this->call + 1;
    });
    $payload = dict[];
    $dispatcher->dispatch($payload);
    expect($this->call)->toBeSame(1);
    $dispatcher->unregister($id);
    $dispatcher->register(($_) ==> {
      $this->call = $this->call + 1;
    });
    $dispatcher->dispatch($payload);
    expect($this->call)->toBeSame(2);
  }

  public async function testShouldWaitForCallbacks(): Awaitable<void> {
    $dispatcher = new Dispatcher();
    $token = $dispatcher->register(($_) ==> {
      $this->call = $this->call + 1;
    });
    $callback = ($v) ==> {
      $this->call = $this->call + 1;
    };
    $dispatcher->register(($dict) ==> {
      $dispatcher->waitFor(vec[$token]);
      expect($this->call)->toBeSame(1);
      $callback($dict);
    });
    $payload = dict[];
    $dispatcher->dispatch($payload);
    expect($this->call)->toBeSame(2);
  }

  public async function testShouldWaitForAsyncCallbacks(): Awaitable<void> {
    $dispatcher = new Dispatcher();
    $callback = ($v) ==> {
      $this->call = $this->call + 1;
    };

    $token = await async {
      return $dispatcher->register(($_) ==> {
        $this->call = $this->call + 1;
      });
    };
      
    await async {
      $dispatcher->register(($dict) ==> {
        $dispatcher->waitFor(vec[$token]);
        expect($this->call)->toBeSame(1);
        $callback($dict);
      });
    };
    $payload = dict[];
    $dispatcher->dispatch($payload);
    expect($this->call)->toBeSame(2);
  }

  public async function testShouldThrowDispatching(): Awaitable<void> {
    $dispatcher = new Dispatcher();
    $dispatcher->register(($payload) ==> {
      $this->call = $this->call + 1;
      $dispatcher->dispatch($payload);
    });
    $payload = dict[];
    expect(() ==> $dispatcher->dispatch($payload))
      ->toThrow(InvariantException::class);
    expect($this->call)->toBeSame(1);  
  }

  public async function testShouldThrowWaitFor(): Awaitable<void> {
    $dispatcher = new Dispatcher();
    $token = $dispatcher->register(($payload) ==> {
      $this->call = $this->call + 1;
    });
    expect(() ==> $dispatcher->waitFor(vec[$token]))
      ->toThrow(InvariantException::class);
  }

  public async function testShouldThrowWaitForInvalidToken(): Awaitable<void> {
    $dispatcher = new Dispatcher();
    $token = '1111111';
    $dispatcher->register(($_) ==> {
      $dispatcher->waitFor(vec[$token]);
    });
    expect(() ==> $dispatcher->dispatch(dict[]))
      ->toThrow(OutOfBoundsException::class);
  }

  public async function afterEachTestAsync(): Awaitable<void> {
    $this->call = 0;
  }
}
