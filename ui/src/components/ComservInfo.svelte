<script>
  import InfoBar from './InfoBar.svelte';

  let comserv = false;

  window.addEventListener('message', ({ data }) => {
    if (data.comserv !== undefined) comserv = data.comserv;
  });

  $: formatedDate = comserv ? new Date((comserv.start || 0) * 1000).toLocaleString('en-GB') : false;
</script>

{#if comserv && typeof comserv === 'object'}
  <main id="infopanel" class="bg-gray-700 p-2 rounded-xl select-none">
    <div class="text-center font-bold mb-2">Community Service</div>

    <InfoBar title="Tasks Left" value={`${comserv.count || 'Unknown'}/${comserv.all || 'Unknown'}`} />
    <InfoBar title="Reason" value={comserv.reason || 'Unknown'} />
    <InfoBar title="Admin" value={comserv.admin ? comserv.admin.name : 'Unknown'} />
    <InfoBar title="Start Date" value={formatedDate || 'Unknown'} />
  </main>
{/if}
