<script>
  export let title = '';
  export let value = '';
</script>

<div class="grid grid-cols-2 gap-1 px-2 text-center items-center bg-slate-800 border-b border-gray-900">
  <div class="max-w-[10rem]">{title}</div>
  <div class="max-w-xs">
    {value}
  </div>
</div>
