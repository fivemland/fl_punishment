<script>
  const buttons = [
    { name: 'comserv', label: 'Community Service' },
    { name: 'jail', label: 'Jail' },
    { name: 'ban', label: 'Ban' },
  ];
  let visible = true;
  let selectedTab = 'comserv';

  $: activeTab = buttons.filter((button) => button.name === selectedTab)[0];

  let users = [];

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

  function remove(identifier) {
    fetch(`https://${GetParentResourceName()}/removeUser`, {
      method: 'POST',
      body: JSON.stringify({
        selectedTab,
        identifier,
      }),
    });
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
    <div class="flex justify-center">
      {#each buttons as button}
        <button on:click={() => selectTab(button.name)} class="btn btn-sm btn-info mx-1">
          {button.label}
        </button>
      {/each}
    </div>
    <div class="flex justify-center mt-2 mb-2">
      <input type="text" placeholder="Search" class="input input-bordered input-sm w-2/6" />
    </div>

    {activeTab.label}
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
