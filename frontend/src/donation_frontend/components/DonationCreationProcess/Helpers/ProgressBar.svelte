<script>
    import { onMount } from "svelte";
	import { currentDonationCreationObject } from "../../../store";

	export let steps = [];
	export let currentActive = 1;

	let circles, progress;
	
	export const handleProgress = (stepIncrement) => {
		circles = document.querySelectorAll('.circle');
		if(stepIncrement == 1){
			currentActive++;

			if(currentActive > circles.length) {
				currentActive = circles.length;
			};
		} else {
			currentActive--;

			if(currentActive < 1) {
				currentActive = 1;
			};
		};

    	update();
	};
	
	function update() {
		circles = document.querySelectorAll('.circle');
		if (circles) {
			circles.forEach((circle, idx) => {
				if(idx < currentActive) {
					circle.classList.add('active');
				} else {
					circle.classList.remove('active');
				};
			});
		};

		const actives = document.querySelectorAll('.active');
		if (actives && progress) {
			progress.style.width = (actives.length - 1) / (circles.length - 1) * 100 + '%';
		};
	};

	const initSubscription = async () => {
		currentDonationCreationObject.subscribe((value) => {
			currentActive = value.currentActiveFormStepIndex;
			if (update) {
				update();
			};
		});    
  	};

  	onMount(initSubscription);
	
</script>

<div class="progress-container" bind:this={circles}>
	<div class="progress" bind:this={progress}></div>
	{#each steps as step, i}
		<div class="circle {i == 0 ? 'active' : ''}" data-title={step} >{i+1}</div>
	{/each}
</div>


<style>
	.progress-container {
		display: flex;
		justify-content: space-between;
		position: relative;
		margin-bottom: 30px;
		margin-left: 20px;
		margin-right: 30px;
		max-width: 100%;
		/* width: 350px; */
		align-items: center;
	}

	.progress-container::before {
		content: '';
		background-color: #e0e0e0;
		position: absolute;
		top: 50%;
		left: 0;
		transform: translateY(-50%);
		height: 4px;
		width: 100%;
		z-index: -1;
	}

	.progress {
		background-color: #3498db;
		position: absolute;
		top: 50%;
		left: 0;
		transform: translateY(-50%);
		height: 4px;
		width: 0%;
		z-index: -1;
		transition: 0.4s ease;
	}

	.circle {
		background-color: #fff;
		color: #999;
		border-radius: 50%;
		height: 30px;
		width: 30px;
		display: flex;
		align-items: center;
		justify-content: center;
		border: 3px solid #e0e0e0;
		transition: 0.4s ease;
		cursor: pointer;
	}
	
	.circle::after{
		content: attr(data-title) " ";
		position: absolute;
		bottom: 35px;
		color: #999;
		transition: 0.4s ease;
		font-size: 0.7rem; /* Start with a smaller font size */
        white-space: nowrap; /* Prevents the title from wrapping */
	}

	/* Medium devices (tablets, 768px and up) */
    @media (min-width: 768px) {
        .circle::after {
            font-size: 0.875rem; /* Slightly larger font size */
        }
    }

    /* Large devices (desktops, 1024px and up) */
    @media (min-width: 1024px) {
        .circle::after {
            font-size: 1rem; /* Larger font size for larger screens */
        }
    }
	
	.circle.active::after {
		color: #3498db;
	}

	.circle.active {
		border-color: #3498db;
	}
</style>