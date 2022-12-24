<script lang="ts">
</script>

<header>
    <h1>Joey Chan</h1>
    <nav>
        <div class="links">
            <div>About</div>
            <div>Work</div>
            <div class="dropdown">
                <div class="dropdown-first">
                    Projects
                </div>
                <div class="dropdown-content">
                    <div>hello</div>
                    <div>fdjskal</div>
                <div/>
            </div>
        </div>
    </nav>
</header>

<style>
    header {
        display: flex;
        justify-content: space-between;
    }

    h1 {
        font-size: 1em;
    }

    .links {
        display: flex;
    }

    .links > * {
        padding: 0 10px 0 10px;
    }

    .links *:hover {
        background-color: grey;
    }

    .dropdown {
        position: relative;
    }

    .dropdown-content {
        display: none;
        position: absolute;
    }

    .dropdown:hover .dropdown-content {
        display:block;
    }
</style>
