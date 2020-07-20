namespace Nazg\Dispatcher;

use namespace HH\Lib\{Dict, C};
use function array_key_exists;

type DispatchToken = string;

class Dispatcher<TPayload> {
  
  private string $prefix = 'ID_';
  private ?TPayload $pendingPayload = null;

  public function __construct(
    private dict<DispatchToken, (function(TPayload):void)> $callbacks = dict[],
    private bool $isDispatching = false,
    private dict<DispatchToken, bool> $isHandled = dict[],
    private dict<DispatchToken, bool> $isPending = dict[],
    private int $lastID = 1,
  ) { }

  public function register(
    (function(TPayload):void) $callback
  ): DispatchToken {
    $this->lastID = $this->lastID + 1;
    $id = $this->prefix . $this->lastID;
    $this->callbacks[$id] = $callback;
    return $id;
  }

  public function unregister(DispatchToken $id): void {
    invariant(
      array_key_exists($id, $this->callbacks),
      'Dispatcher.unregister(...): `%s` does not map to a registered callback.',
      $id
    );
    $this->callbacks = Dict\filter_with_key(
      $this->callbacks,
      ($k, $_) ==> $k !== $id
    );
  }

  public function waitFor(
    vec<DispatchToken> $ids
  ): void {
    invariant(
      $this->isDispatching,
      'waitFor(...): Must be invoked while dispatching.'
    );
    for ($i = 0; $i < C\count($ids); $i++) {
      $id = $ids[$i];
      if($this->isPending[$id]) {
        invariant(
          $this->isHandled[$id],
          'waitFor(...): Circular dependency detected while waiting for `%s`.',
          $id
        );
        continue;
      }
      invariant(
        $this->callbacks[$id],
        'waitFor(...): `%s` does not map to a registered callback.',
        $id
      );
      $this->invokeCallback($id);
    }
  }

  public function dispatch(TPayload $payload): void {
    invariant(
      !$this->isDispatching,
      'dispatch(...): Cannot dispatch in the middle of a dispatch.'
    );
    $this->startDispatching($payload);
    try {
      foreach ($this->callbacks as $key => $value) {
        if($this->isPending[$key]) {
          continue;
        }
        $this->invokeCallback($key);
      } 
    } finally {
      $this->stopDispatching();
    }
  }

  public function isDispatching(): bool {
    return $this->isDispatching;
  }

  private function invokeCallback(DispatchToken $id): void {
    $this->isPending[$id] = true;
    if(array_key_exists($id, $this->callbacks)) {
      if($this->pendingPayload is nonnull) {
        $this->callbacks[$id]($this->pendingPayload);
      }
    }
    $this->isHandled[$id] = true;
  }

  private function startDispatching(
    TPayload $payload
  ): void {
    Dict\map_with_key($this->callbacks, ($k, $_) ==> {
      $this->isPending[$k] = false;
      $this->isHandled[$k] = false;
    });
    $this->pendingPayload = $payload;
    $this->isDispatching = true;
  }

  private function stopDispatching(): void {
    $this->pendingPayload = null;
    $this->isDispatching = false;
  }
}
