# PicJS Examples

## Minimal Jest example

```ts
// global-setup.ts
import { PocketIcServer } from "@dfinity/pic";

module.exports = async function (): Promise<void> {
  const pic = await PocketIcServer.start();
  process.env.PIC_URL = pic.getUrl();
  global.__PIC__ = pic;
};
```

```ts
// global-teardown.ts
module.exports = async function () {
  await global.__PIC__.stop();
};
```

```ts
// example.spec.ts
import { PocketIc } from "@dfinity/pic";
import { type _SERVICE } from "../../declarations/backend/backend.did";

describe("backend canister", () => {
  let pic: PocketIc;

  beforeEach(async () => {
    pic = await PocketIc.create(process.env.PIC_URL);
    const fixture = await pic.setupCanister<_SERVICE>({
      idlFactory,
      wasm: WASM_PATH,
    });
    // use fixture.actor + fixture.canisterId
  });

  afterEach(async () => {
    await pic.tearDown();
  });
});
```

## Minimal `vitest` example

```ts
// global-setup.ts
import type { GlobalSetupContext } from "vitest/node";
import { PocketIcServer } from "@dfinity/pic";

let pic: PocketIcServer | undefined;

export async function setup(ctx: GlobalSetupContext): Promise<void> {
  pic = await PocketIcServer.start();
  ctx.provide("PIC_URL", pic.getUrl());
}

export async function teardown(): Promise<void> {
  await pic?.stop();
}
```

```ts
// example.spec.ts
import { beforeEach, afterEach, describe, expect, it, inject } from "vitest";
import { PocketIc } from "@dfinity/pic";

describe("backend canister", () => {
  let pic: PocketIc;

  beforeEach(async () => {
    pic = await PocketIc.create(inject("PIC_URL"));
  });

  afterEach(async () => {
    await pic.tearDown();
  });
});
```

## Minimal Bun example

```ts
// global-setup.ts
import { beforeAll, afterAll } from "bun:test";
import { PocketIcServer } from "@dfinity/pic";

let pic: PocketIcServer | undefined;

beforeAll(async () => {
  pic = await PocketIcServer.start();
  process.env.PIC_URL = pic.getUrl();
});

afterAll(async () => {
  await pic?.stop();
});
```

```ts
// example.spec.ts
import { beforeEach, afterEach, describe, expect, it } from "bun:test";
import { PocketIc } from "@dfinity/pic";

describe("backend canister", () => {
  let pic: PocketIc;

  beforeEach(async () => {
    pic = await PocketIc.create(process.env.PIC_URL);
  });

  afterEach(async () => {
    await pic.tearDown();
  });
});
```
