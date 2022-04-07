<script>
  const buttons = [
    { name: 'comserv', label: 'Community Service' },
    { name: 'jail', label: 'Jail' },
    { name: 'ban', label: 'Ban' },
  ];
  let visible = true;
  let selectedTab = 'comserv';

  $: activeTab = buttons.filter((button) => button.name === selectedTab)[0];

  let users = [
    { identifier: 'csokifasz', name: 'Clark fasz Melton', reason: 'Teszt', count: 10, all: 20 },
    {
      identifier: 'csokifasz',
      name: 'Frank Johns',
      reason:
        'Tesztasdhaskldhaksldhklashkdlhask hdlkas hkashd lkashd klhaskld hakls hklashd klashkld haskl haksl hklas hklash kldhaskl dhklasd hklashd klashd klashkld haskld haklsd hkasdh klashdlk',
      count: 10,
      all: 20,
    },
  ];

  let search = '';

  $: filteredUsers = users.filter((user) => user.name.toLowerCase().includes(search.toLowerCase()));

  async function selectTab(name) {
    selectedTab = name;

    const response = await fetch(`https://${GetParentResourceName()}/requestUsers`, {
      method: 'POST',
      body: JSON.stringify({
        selectedTab,
      }),
    });

    const responseJson = await response.json();

    if (responseJson.error) return (users = []);

    users = responseJson.users;
  }

  window.addEventListener('message', ({ data }) => {
    if (data.adminPanel !== undefined) visible = data.adminPanel;
  });

  function close() {
    fetch(`https://${GetParentResourceName()}/closeAdminPanel`);
  }

  function remove(user) {
    fetch(`https://${GetParentResourceName()}/removeUser`, {
      method: 'POST',
      body: JSON.stringify({
        selectedTab,
        identifier: user.identifier,
      }),
    });
  }

  let userInfo = false;

  async function requestUserData(user) {
    userInfo = false;

    const response = await fetch(`https://${GetParentResourceName()}/requestUserData`, {
      method: 'POST',
      body: JSON.stringify({
        identifier: user.identifier,
      }),
    });

    const responseJson = await response.json();

    console.log(responseJson);
  }
</script>

{#if visible}
  <main class="bg-slate-700 rounded-lg w-2/5 p-2">
    <div class="flex justify-between items-center text-xl">
      Punishments

      <button on:click={close} class="text-error">
        <i class="fa-solid fa-xmark" />
      </button>
    </div>
    <div class="flex justify-between">
      <div class="flex">
        {#each buttons as button}
          <button on:click={() => selectTab(button.name)} class="btn btn-sm btn-info mx-1">
            {button.label}
          </button>
        {/each}
      </div>
      <div class="mb-2">
        <input bind:value={search} type="text" placeholder="Search" class="input input-bordered input-sm w-full" />
      </div>
    </div>

    <div class="max-h-96 overflow-y-auto">
      {#if search.length > 0 && filteredUsers.length <= 0}
        <div class="text-center text-warning text-lg mt-4">Users not found!</div>
      {/if}

      {#each filteredUsers as user}
        <div class="grid grid-flow-col gap-2 items-center bg-slate-800 p-2 rounded-md border-b border-gray-900">
          <div class="w-40">{user.name || 'Ismeretlen'}</div>
          <div class="w-60 text-center">
            <div class="tooltip tooltip-left" data-tip="Reason">
              {user.reason || 'Unknown'}
            </div>
          </div>
          <div>
            <div class="tooltip tooltip-right" data-tip="Count">
              {user.count || 0}/{user.all || 0}
            </div>
          </div>
          <div class="ml-auto">
            <label on:click={() => requestUserData(user)} class="btn btn-sm btn-circle btn-primary modal-button" for="my-modal">
              <i class="fa-solid fa-info" />
            </label>

            <button on:click={() => remove(user)} class="btn btn-sm btn-circle btn-error">
              <i class="fa-solid fa-trash-can" />
            </button>
          </div>
        </div>

        <input type="checkbox" id="my-modal" class="modal-toggle" />
        <div class="modal">
          <div class="modal-box bg-gray-800">
            <label for="my-modal" class="btn btn-sm btn-circle absolute right-2 top-2">✕</label>
            <h3 class="font-bold text-lg">User Informations</h3>
            <table class="table table-compact w-full mt-3 py-4">
              <tbody>
                <tr>
                  <td>Start Date</td>
                  <td class="text-right">1900.01.01</td>
                </tr>
                <tr>
                  <td>Admin</td>
                  <td class="text-right">Csoki</td>
                </tr>
                <tr>
                  <td>Admin Identifier</td>
                  <td class="text-right">asdasd</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      {/each}
    </div>
  </main>
{/if}

<style>
  main {
    position: absolute;
    left: 50%;
    top: 50%;
    transform: translate(-50%, -50%);
  }
</style>
