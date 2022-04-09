<script>
  import InfoBar from './InfoBar.svelte';

  let jail = false;

  window.addEventListener('message', ({ data }) => {
    if (data.jail !== undefined) {
      jail = data.jail;
    }
  });

  $: formatedDate = jail ? new Date((jail.start || 0) * 1000).toLocaleString('en-GB') : false;
</script>

{#if jail && typeof jail === 'object'}
  <main id="infopanel" class="bg-gray-700 p-2 rounded-xl select-none">
    <div class="text-center font-bold mb-2">Admin Jail</div>

    <InfoBar title="Time Left" value={`${(jail.all || 0) - (jail.count || 0)} minutes`} />
    <InfoBar title="All Time" value={`${jail.all} minutes`} />
    <InfoBar title="Reason" value={jail.reason} />
    <InfoBar title="Admin" value={jail.admin ? jail.admin.name : 'Unknown'} />
    <InfoBar title="Start Date" value={formatedDate} />
  </main>
{/if}
